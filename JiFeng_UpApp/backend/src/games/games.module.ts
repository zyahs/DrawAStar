import { Module } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { GamesController } from './games.controller';
import { GamesService } from './games.service';

@Module({
  controllers: [GamesController],
  providers: [GamesService, PrismaService],
})
export class GamesModule {}
