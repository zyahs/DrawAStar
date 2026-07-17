import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AdminModule } from './admin/admin.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { AuthModule } from './auth/auth.module';
import { ChatModule } from './chat/chat.module';
import { GamesModule } from './games/games.module';
import { MultiplayerModule } from './multiplayer/multiplayer.module';
import { PrismaService } from './common/prisma.service';
import { SupportModule } from './support/support.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    AuthModule,
    AnalyticsModule,
    UsersModule,
    GamesModule,
    MultiplayerModule,
    ChatModule,
    SupportModule,
    AdminModule,
  ],
  providers: [PrismaService],
})
export class AppModule {}
