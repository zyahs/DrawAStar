import { GameKind } from '@prisma/client';
import { IsBoolean, IsEnum, IsInt, IsObject, IsOptional, Max, Min } from 'class-validator';

export class CreateGameRecordDto {
  @IsEnum(GameKind)
  kind!: GameKind;

  @IsInt()
  @Min(0)
  @Max(100000000)
  score!: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(10)
  difficulty?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  durationMs?: number;

  @IsOptional()
  @IsBoolean()
  win?: boolean;

  @IsOptional()
  @IsObject()
  extra?: Record<string, unknown>;
}
