import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { GameKind } from '@prisma/client';
import { CurrentUser, RequestUser } from '../common/auth.decorator';
import { CreateRoomDto, JoinRoomDto, SendGameMessageDto } from './multiplayer.dto';
import { MultiplayerService } from './multiplayer.service';

@Controller('multiplayer')
export class MultiplayerController {
  constructor(private readonly multiplayer: MultiplayerService) {}

  @Get('rooms')
  list(@Query('kind') kind?: GameKind, @Query('serviceType') serviceType?: string) {
    return this.multiplayer.listRooms(kind, serviceType);
  }

  @Post('rooms')
  create(@CurrentUser() user: RequestUser, @Body() dto: CreateRoomDto) {
    return this.multiplayer.createRoom(user.sub, dto.kind, dto.displayName, dto.serviceType);
  }

  @Post('rooms/:roomId/join')
  join(@CurrentUser() user: RequestUser, @Param('roomId') roomId: string, @Body() dto: JoinRoomDto) {
    return this.multiplayer.joinRoom(user.sub, roomId, dto.displayName, dto.serviceType);
  }

  @Get('rooms/:roomId')
  poll(@CurrentUser() user: RequestUser, @Param('roomId') roomId: string, @Query('since') since?: string) {
    return this.multiplayer.poll(user.sub, roomId, since ? Number(since) : 0);
  }

  @Post('rooms/:roomId/messages')
  send(@CurrentUser() user: RequestUser, @Param('roomId') roomId: string, @Body() dto: SendGameMessageDto) {
    return this.multiplayer.send(user.sub, roomId, dto);
  }
}
