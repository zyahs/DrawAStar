import { IsOptional, IsString, MaxLength } from 'class-validator';

export class GuestLoginDto {
  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceName?: string;
}

export class AppleLoginDto {
  @IsString()
  @MaxLength(512)
  identityToken!: string;

  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceId?: string;
}

export class RefreshTokenDto {
  @IsString()
  refreshToken!: string;
}
