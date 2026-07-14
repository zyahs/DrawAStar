import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { GameKind } from '@prisma/client';
import { CurrentUser, RequestUser } from '../common/auth.decorator';
import { CreateGameRecordDto } from './games.dto';
import { GamesService } from './games.service';

@Controller('games')
export class GamesController {
  constructor(private readonly games: GamesService) {}

  @Post('records')
  record(@CurrentUser() user: RequestUser, @Body() dto: CreateGameRecordDto) {
    return this.games.record(user.sub, dto);
  }

  @Get('leaderboard')
  leaderboard(@Query('kind') kind: GameKind, @Query('take') take?: string) {
    return this.games.leaderboard(kind, take ? Number(take) : 50);
  }

  @Get('config')
  config() {
    return this.games.configs();
  }
}
