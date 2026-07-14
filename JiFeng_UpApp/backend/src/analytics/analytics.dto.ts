import { GameKind } from '@prisma/client';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsDateString,
  IsEnum,
  IsIn,
  IsObject,
  IsOptional,
  IsString,
  Length,
  ValidateNested,
} from 'class-validator';

export const ANALYTICS_EVENT_NAMES = [
  'app_session_start',
  'app_session_end',
  'game_card_click',
  'game_enter',
  'game_start',
  'game_finish',
  'game_exit',
  'game_mode_select',
  'room_create',
  'room_join',
  'chat_send',
  'skin_apply',
] as const;

export class AnalyticsEventDto {
  @IsString()
  @Length(8, 64)
  eventId!: string;

  @IsString()
  @Length(8, 64)
  appSessionId!: string;

  @IsOptional()
  @IsString()
  @Length(8, 64)
  gameSessionId?: string;

  @IsString()
  @IsIn([...ANALYTICS_EVENT_NAMES])
  name!: string;

  @IsOptional()
  @IsEnum(GameKind)
  kind?: GameKind;

  @IsString()
  @IsIn(['ios', 'android'])
  platform!: string;

  @IsString()
  @Length(1, 32)
  appVersion!: string;

  @IsDateString()
  occurredAt!: string;

  @IsOptional()
  @IsObject()
  properties?: Record<string, unknown>;
}

export class AnalyticsBatchDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => AnalyticsEventDto)
  events!: AnalyticsEventDto[];
}
