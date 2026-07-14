import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { SendChatMessageDto } from './chat.dto';

@Injectable()
export class ChatService {
  constructor(private readonly prisma: PrismaService) {}

  async list(room = 'global', take = 50) {
    const messages = await this.prisma.chatMessage.findMany({
      where: { room: this.cleanRoom(room) },
      orderBy: { createdAt: 'desc' },
      take: Math.min(Math.max(take, 1), 100),
      include: {
        user: {
          select: {
            id: true,
            displayName: true,
            avatarSymbol: true,
            avatarUrl: true,
          },
        },
      },
    });
    return messages.reverse();
  }

  async send(userId: string, dto: SendChatMessageDto) {
    const content = dto.content.trim();
    if (!content) throw new BadRequestException('message is empty');
    return this.prisma.chatMessage.create({
      data: {
        userId,
        room: this.cleanRoom(dto.room),
        content,
      },
      include: {
        user: {
          select: {
            id: true,
            displayName: true,
            avatarSymbol: true,
            avatarUrl: true,
          },
        },
      },
    });
  }

  private cleanRoom(room?: string) {
    const value = (room || 'global').trim();
    return value.length > 0 ? value : 'global';
  }
}
