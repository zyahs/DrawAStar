import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AdminRole, Prisma, UserStatus } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../common/prisma.service';

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async bootstrap(bootstrapKey: string, username: string, password: string, role: AdminRole = AdminRole.OWNER) {
    if (!process.env.ADMIN_BOOTSTRAP_KEY || bootstrapKey !== process.env.ADMIN_BOOTSTRAP_KEY) {
      throw new UnauthorizedException('invalid bootstrap key');
    }
    const count = await this.prisma.adminUser.count();
    if (count > 0) throw new BadRequestException('admin already exists');

    const admin = await this.prisma.adminUser.create({
      data: {
        username,
        role,
        passwordHash: await bcrypt.hash(password, 10),
      },
    });
    return this.publicAdmin(admin);
  }

  async login(username: string, password: string) {
    const admin = await this.prisma.adminUser.findUnique({ where: { username } });
    if (!admin) throw new UnauthorizedException('invalid credentials');
    const ok = await bcrypt.compare(password, admin.passwordHash);
    if (!ok) throw new UnauthorizedException('invalid credentials');

    const accessToken = await this.jwt.signAsync(
      { sub: admin.id, role: admin.role, isAdmin: true },
      {
        secret: process.env.JWT_ACCESS_SECRET || 'dev_access_secret',
        expiresIn: '2h',
      },
    );
    return { admin: this.publicAdmin(admin), accessToken };
  }

  users(page = 1, pageSize = 30) {
    const skip = (Math.max(page, 1) - 1) * Math.min(Math.max(pageSize, 1), 100);
    const take = Math.min(Math.max(pageSize, 1), 100);
    return this.prisma.user.findMany({
      skip,
      take,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        status: true,
        displayName: true,
        avatarUrl: true,
        avatarSymbol: true,
        coins: true,
        level: true,
        totalScore: true,
        totalGames: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  userDetail(id: string) {
    return this.prisma.user.findUnique({
      where: { id },
      include: {
        identities: true,
        sessions: {
          orderBy: { createdAt: 'desc' },
          take: 20,
        },
        gameRecords: {
          orderBy: { createdAt: 'desc' },
          take: 30,
        },
      },
    });
  }

  async updateUserStatus(adminId: string, userId: string, status: UserStatus) {
    const user = await this.prisma.user.update({ where: { id: userId }, data: { status } });
    await this.prisma.adminAuditLog.create({
      data: {
        adminId,
        targetId: userId,
        action: 'user.status.update',
        detail: { status } as Prisma.InputJsonValue,
      },
    });
    return user;
  }

  upsertConfig(key: string, value: Record<string, unknown>, note?: string) {
    return this.prisma.gameConfig.upsert({
      where: { key },
      update: { value: value as Prisma.InputJsonValue, note },
      create: { key, value: value as Prisma.InputJsonValue, note },
    });
  }

  auditLogs(take = 100) {
    return this.prisma.adminAuditLog.findMany({
      take: Math.min(Math.max(take, 1), 200),
      orderBy: { createdAt: 'desc' },
      include: { admin: { select: { id: true, username: true, role: true } } },
    });
  }

  private publicAdmin(admin: { id: string; username: string; role: AdminRole }) {
    return { id: admin.id, username: admin.username, role: admin.role };
  }
}
