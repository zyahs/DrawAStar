import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { GameKind } from '@prisma/client';
import { randomBytes } from 'crypto';
import { SendGameMessageDto } from './multiplayer.dto';

type Peer = {
  peerId: string;
  userId: string;
  displayName: string;
  role: 'host' | 'client';
  joinedAt: number;
  lastSeenAt: number;
};

type Message = {
  seq: number;
  type: string;
  from: string;
  to?: string;
  ts: number;
  payload: Record<string, unknown>;
};

type Room = {
  roomId: string;
  kind: GameKind;
  serviceType: string;
  hostPeerId: string;
  createdAt: number;
  updatedAt: number;
  peers: Peer[];
  messages: Message[];
  nextSeq: number;
};

@Injectable()
export class MultiplayerService {
  private readonly rooms = new Map<string, Room>();
  private readonly hostOnlyMessageTypes = new Set([
    'card_round',
    'card_deal',
    'card_result',
    'identity',
    'vote_list',
    'vote_result',
    'king_deal',
  ]);

  listRooms(kind?: GameKind, serviceType?: string) {
    this.sweep();
    return Array.from(this.rooms.values())
      .filter((room) => (!kind || room.kind === kind) && (!serviceType || room.serviceType === serviceType))
      .sort((a, b) => b.updatedAt - a.updatedAt)
      .slice(0, 20)
      .map((room) => ({
        roomId: room.roomId,
        kind: room.kind,
        serviceType: room.serviceType,
        peerCount: room.peers.length,
        hostPeerId: room.hostPeerId,
        updatedAt: room.updatedAt,
      }));
  }

  createRoom(userId: string, kind: GameKind, displayName?: string, serviceType?: string) {
    this.sweep();
    const roomId = this.newRoomId();
    const peer = this.peer(userId, displayName, 'host');
    const room: Room = {
      roomId,
      kind,
      serviceType: serviceType || kind.toLowerCase(),
      hostPeerId: peer.peerId,
      createdAt: Date.now(),
      updatedAt: Date.now(),
      peers: [peer],
      messages: [],
      nextSeq: 1,
    };
    this.rooms.set(roomId, room);
    this.append(room, { type: 'hello', from: peer.peerId, payload: { role: 'host', displayName: peer.displayName } });
    return this.snapshot(room, peer.peerId, 0);
  }

  joinRoom(userId: string, roomId: string, displayName?: string, serviceType?: string) {
    this.sweep();
    const room = this.getRoom(roomId);
    if (serviceType && room.serviceType !== serviceType) {
      throw new BadRequestException('room game type mismatch');
    }
    let peer = room.peers.find((p) => p.userId === userId);
    if (!peer) {
      peer = this.peer(userId, displayName, 'client');
      room.peers.push(peer);
      this.append(room, { type: 'hello', from: peer.peerId, payload: { role: 'client', displayName: peer.displayName } });
    } else if (displayName) {
      peer.displayName = displayName;
    }
    peer.lastSeenAt = Date.now();
    room.updatedAt = Date.now();
    return this.snapshot(room, peer.peerId, 0);
  }

  poll(userId: string, roomId: string, since = 0) {
    this.sweep();
    const room = this.getRoom(roomId);
    const peer = room.peers.find((p) => p.userId === userId);
    if (!peer) throw new ForbiddenException('join room before polling');
    peer.lastSeenAt = Date.now();
    return this.snapshot(room, peer.peerId, since);
  }

  send(userId: string, roomId: string, dto: SendGameMessageDto) {
    const room = this.getRoom(roomId);
    const peer = room.peers.find((p) => p.userId === userId);
    if (!peer) throw new ForbiddenException('join room before sending messages');
    if (this.hostOnlyMessageTypes.has(dto.type) && peer.peerId !== room.hostPeerId) {
      throw new ForbiddenException('only host can send this message');
    }
    if (dto.type === 'card_reveal' && dto.to !== room.hostPeerId) {
      throw new BadRequestException('card reveal must be sent to host');
    }
    if (dto.to && !room.peers.some((candidate) => candidate.peerId === dto.to)) {
      throw new BadRequestException('target peer not found');
    }
    const message = this.append(room, {
      type: dto.type,
      from: peer.peerId,
      to: dto.to,
      payload: dto.payload || {},
    });
    return { message };
  }

  private getRoom(roomId: string) {
    const room = this.rooms.get(roomId.toUpperCase());
    if (!room) throw new NotFoundException('room not found');
    return room;
  }

  private peer(userId: string, displayName: string | undefined, role: 'host' | 'client'): Peer {
    return {
      peerId: userId,
      userId,
      displayName: displayName || '继风玩家',
      role,
      joinedAt: Date.now(),
      lastSeenAt: Date.now(),
    };
  }

  private append(room: Room, input: Omit<Message, 'seq' | 'ts'> & { ts?: number }) {
    const message: Message = {
      seq: room.nextSeq++,
      type: input.type,
      from: input.from,
      to: input.to,
      ts: input.ts || Date.now() / 1000,
      payload: input.payload,
    };
    room.messages.push(message);
    if (room.messages.length > 300) room.messages.shift();
    room.updatedAt = Date.now();
    return message;
  }

  private snapshot(room: Room, selfPeerId: string | undefined, since: number) {
    return {
      roomId: room.roomId,
      kind: room.kind,
      serviceType: room.serviceType,
      selfPeerId,
      hostPeerId: room.hostPeerId,
      peers: room.peers.map((peer) => ({
        peerId: peer.peerId,
        displayName: peer.displayName,
        role: peer.role,
        joinedAt: peer.joinedAt,
      })),
      messages: room.messages.filter((m) =>
        m.seq > since && (!m.to || m.to === selfPeerId || m.from === selfPeerId),
      ),
      latestSeq: room.nextSeq - 1,
      serverTime: Date.now(),
    };
  }

  private newRoomId() {
    let roomId = '';
    do {
      roomId = randomBytes(3).toString('hex').toUpperCase();
    } while (this.rooms.has(roomId));
    return roomId;
  }

  private sweep() {
    const now = Date.now();
    for (const [id, room] of this.rooms) {
      if (now - room.updatedAt > 1000 * 60 * 60 * 6) this.rooms.delete(id);
    }
  }
}
