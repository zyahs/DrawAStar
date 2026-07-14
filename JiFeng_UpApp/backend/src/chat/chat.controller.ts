import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { CurrentUser, RequestUser } from '../common/auth.decorator';
import { ChatService } from './chat.service';
import { SendChatMessageDto } from './chat.dto';

@Controller('chat')
export class ChatController {
  constructor(private readonly chat: ChatService) {}

  @Get('messages')
  messages(@Query('room') room?: string, @Query('take') take?: string) {
    return this.chat.list(room, take ? Number(take) : 50);
  }

  @Post('messages')
  send(@CurrentUser() user: RequestUser, @Body() dto: SendChatMessageDto) {
    return this.chat.send(user.sub, dto);
  }
}
