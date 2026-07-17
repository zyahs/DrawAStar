import { Body, Controller, Post, Req } from '@nestjs/common';
import { Request } from 'express';
import { Public } from '../common/auth.decorator';
import { CreateSupportRequestDto } from './support.dto';
import { SupportService } from './support.service';

@Controller('support')
export class SupportController {
  constructor(private readonly support: SupportService) {}

  @Public()
  @Post('requests')
  create(@Body() dto: CreateSupportRequestDto, @Req() request: Request) {
    return this.support.create(dto, request.ip || 'unknown');
  }
}
