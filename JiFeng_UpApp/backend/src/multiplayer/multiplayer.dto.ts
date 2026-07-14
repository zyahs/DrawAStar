import { GameKind } from '@prisma/client';
import { IsEnum, IsObject, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateRoomDto {
  @IsEnum(GameKind)
  kind!: GameKind;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  displayName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  serviceType?: string;
}

export class JoinRoomDto {
  @IsOptional()
  @IsString()
  @MaxLength(32)
  displayName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  serviceType?: string;
}

export class SendGameMessageDto {
  @IsString()
  @MaxLength(64)
  type!: string;

  @IsOptional()
  @IsString()
  @MaxLength(128)
  from?: string;

  @IsOptional()
  @IsString()
  @MaxLength(128)
  to?: string;

  @IsOptional()
  @IsObject()
  payload?: Record<string, unknown>;
}
