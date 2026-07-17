import { BadRequestException, HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { randomBytes } from 'crypto';
import { PrismaService } from '../common/prisma.service';
import { CreateSupportRequestDto } from './support.dto';

@Injectable()
export class SupportService {
  private readonly requestsByAddress = new Map<string, number[]>();

  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateSupportRequestDto, address: string) {
    if (dto.website) throw new BadRequestException('invalid request');
    this.checkRateLimit(address);

    const referenceId = this.newReferenceId();
    const receivedAt = new Date();
    await this.prisma.adminAuditLog.deleteMany({
      where: {
        action: 'support.request.created',
        createdAt: { lt: new Date(receivedAt.getTime() - 180 * 24 * 60 * 60 * 1000) },
      },
    });
    await this.prisma.adminAuditLog.create({
      data: {
        action: 'support.request.created',
        detail: {
          referenceId,
          type: dto.type,
          userId: dto.userId?.trim() || null,
          contact: dto.contact?.trim() || null,
          content: dto.content.trim(),
          platform: dto.platform?.trim() || null,
          appVersion: dto.appVersion?.trim() || null,
          receivedAt: receivedAt.toISOString(),
        } as Prisma.InputJsonValue,
      },
    });

    return { ok: true, referenceId, receivedAt };
  }

  private checkRateLimit(address: string) {
    const now = Date.now();
    const cutoff = now - 10 * 60 * 1000;
    const recent = (this.requestsByAddress.get(address) || []).filter((time) => time > cutoff);
    if (recent.length >= 5) {
      throw new HttpException('too many requests', HttpStatus.TOO_MANY_REQUESTS);
    }
    recent.push(now);
    this.requestsByAddress.set(address, recent);
  }

  private newReferenceId() {
    const day = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    return `YZHX-${day}-${randomBytes(3).toString('hex').toUpperCase()}`;
  }
}
