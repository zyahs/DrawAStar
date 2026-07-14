import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { CurrentUser, RequestUser } from '../common/auth.decorator';
import { AnalyticsBatchDto } from './analytics.dto';
import { AnalyticsService } from './analytics.service';

@Controller('analytics')
export class AnalyticsController {
  constructor(private readonly analytics: AnalyticsService) {}

  @Post('events/batch')
  ingest(@CurrentUser() user: RequestUser, @Body() dto: AnalyticsBatchDto) {
    return this.analytics.ingest(user.sub, dto.events);
  }
}

@UseGuards(AdminGuard)
@Controller('admin/analytics')
export class AdminAnalyticsController {
  constructor(private readonly analytics: AnalyticsService) {}

  @Get('overview')
  overview(@Query('days') days?: string) {
    return this.analytics.overview(days ? Number(days) : 30);
  }

  @Get('games')
  games(@Query('days') days?: string) {
    return this.analytics.gameMetrics(days ? Number(days) : 30);
  }
}
