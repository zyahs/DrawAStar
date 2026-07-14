import { AdminRole, UserStatus } from '@prisma/client';
import { IsEnum, IsObject, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class BootstrapAdminDto {
  @IsString()
  bootstrapKey!: string;

  @IsString()
  @MaxLength(64)
  username!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;

  @IsOptional()
  @IsEnum(AdminRole)
  role?: AdminRole;
}

export class AdminLoginDto {
  @IsString()
  username!: string;

  @IsString()
  password!: string;
}

export class UpdateUserStatusDto {
  @IsEnum(UserStatus)
  status!: UserStatus;
}

export class UpsertConfigDto {
  @IsObject()
  value!: Record<string, unknown>;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  note?: string;
}
