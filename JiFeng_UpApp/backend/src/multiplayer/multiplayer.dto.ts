import { GameKind } from '@prisma/client';
import { IsIn, IsObject, IsOptional, IsString, MaxLength } from 'class-validator';

const multiplayerGameKinds = [
  ...Object.values(GameKind),
  // Keep newly shipped in-memory room types available during rolling deploys,
  // even if a server has not regenerated Prisma Client yet.
  'DRAW_GUESS',
] as const;

export class CreateRoomDto {
  @IsString()
  @IsIn(multiplayerGameKinds)
  kind!: GameKind | 'DRAW_GUESS';

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
