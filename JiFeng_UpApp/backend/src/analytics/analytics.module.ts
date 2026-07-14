import { Module } from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { PrismaService } from '../common/prisma.service';
import { AdminAnalyticsController, AnalyticsController } from './analytics.controller';
import { AnalyticsService } from './analytics.service';

@Module({
  controllers: [AnalyticsController, AdminAnalyticsController],
  providers: [AnalyticsService, PrismaService, AdminGuard],
})
export class AnalyticsModule {}
