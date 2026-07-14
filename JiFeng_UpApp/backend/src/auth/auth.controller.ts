import { Body, Controller, Post, Req } from '@nestjs/common';
import { Request } from 'express';
import { CurrentUser, Public, RequestUser } from '../common/auth.decorator';
import { AppleLoginDto, GuestLoginDto, RefreshTokenDto } from './auth.dto';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Public()
  @Post('guest')
  guest(@Body() dto: GuestLoginDto, @Req() req: Request) {
    return this.auth.guestLogin({
      deviceId: dto.deviceId,
      deviceName: dto.deviceName,
      ipAddress: req.ip,
    });
  }

  @Public()
  @Post('apple')
  apple(@Body() dto: AppleLoginDto, @Req() req: Request) {
    return this.auth.appleLogin(dto.identityToken, {
      deviceId: dto.deviceId,
      ipAddress: req.ip,
    });
  }

  @Public()
  @Post('refresh')
  refresh(@Body() dto: RefreshTokenDto) {
    return this.auth.refresh(dto.refreshToken);
  }

  @Post('logout')
  logout(@CurrentUser() user: RequestUser) {
    return this.auth.revokeSession(user.sub, user.sessionId);
  }
}
