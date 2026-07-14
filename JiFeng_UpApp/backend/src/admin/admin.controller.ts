import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { CurrentUser, Public, RequestUser } from '../common/auth.decorator';
import { AdminGuard } from './admin.guard';
import { AdminService } from './admin.service';
import { AdminLoginDto, BootstrapAdminDto, UpdateUserStatusDto, UpsertConfigDto } from './admin.dto';

@Controller('admin')
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Public()
  @Post('bootstrap')
  bootstrap(@Body() dto: BootstrapAdminDto) {
    return this.admin.bootstrap(dto.bootstrapKey, dto.username, dto.password, dto.role);
  }

  @Public()
  @Post('login')
  login(@Body() dto: AdminLoginDto) {
    return this.admin.login(dto.username, dto.password);
  }

  @UseGuards(AdminGuard)
  @Get('users')
  users(@Query('page') page?: string, @Query('pageSize') pageSize?: string) {
    return this.admin.users(page ? Number(page) : 1, pageSize ? Number(pageSize) : 30);
  }

  @UseGuards(AdminGuard)
  @Get('users/:id')
  userDetail(@Param('id') id: string) {
    return this.admin.userDetail(id);
  }

  @UseGuards(AdminGuard)
  @Patch('users/:id/status')
  updateUserStatus(@CurrentUser() user: RequestUser, @Param('id') id: string, @Body() dto: UpdateUserStatusDto) {
    return this.admin.updateUserStatus(user.sub, id, dto.status);
  }

  @UseGuards(AdminGuard)
  @Post('game-config/:key')
  upsertConfig(@Param('key') key: string, @Body() dto: UpsertConfigDto) {
    return this.admin.upsertConfig(key, dto.value, dto.note);
  }

  @UseGuards(AdminGuard)
  @Get('audit-logs')
  auditLogs(@Query('take') take?: string) {
    return this.admin.auditLogs(take ? Number(take) : 100);
  }
}
