import { Body, Controller, Get, Patch } from '@nestjs/common';
import { CurrentUser, RequestUser } from '../common/auth.decorator';
import { UpdateMeDto } from './users.dto';
import { UsersService } from './users.service';

@Controller('me')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get()
  me(@CurrentUser() user: RequestUser) {
    return this.users.me(user.sub);
  }

  @Patch()
  updateMe(@CurrentUser() user: RequestUser, @Body() dto: UpdateMeDto) {
    return this.users.updateMe(user.sub, dto);
  }
}
