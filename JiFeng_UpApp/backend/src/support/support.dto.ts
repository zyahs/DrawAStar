import { IsIn, IsOptional, IsString, Length, MaxLength } from 'class-validator';

export const SUPPORT_REQUEST_TYPES = [
  'PRIVACY',
  'ACCOUNT_DELETION',
  'CONTENT_REPORT',
  'TECHNICAL',
  'OTHER',
] as const;

export class CreateSupportRequestDto {
  @IsString()
  @IsIn([...SUPPORT_REQUEST_TYPES])
  type!: string;

  @IsOptional()
  @IsString()
  @MaxLength(64)
  userId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(128)
  contact?: string;

  @IsString()
  @Length(5, 2000)
  content!: string;

  @IsOptional()
  @IsString()
  @MaxLength(16)
  platform?: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  appVersion?: string;

  // Hidden form field. Normal users never fill it; bots usually do.
  @IsOptional()
  @IsString()
  @MaxLength(128)
  website?: string;
}
