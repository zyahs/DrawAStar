import { IsOptional, IsString, MaxLength } from 'class-validator';

export class SendChatMessageDto {
  @IsOptional()
  @IsString()
  @MaxLength(80)
  room?: string;

  @IsString()
  @MaxLength(500)
  content!: string;
}
