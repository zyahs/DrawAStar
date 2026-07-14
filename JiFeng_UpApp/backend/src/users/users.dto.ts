import { IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateMeDto {
  @IsOptional()
  @IsString()
  @MaxLength(32)
  displayName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(512)
  avatarUrl?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  avatarSymbol?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  background?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  signature?: string;
}
