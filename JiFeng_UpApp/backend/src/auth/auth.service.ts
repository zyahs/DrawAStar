import { Injectable, UnauthorizedException } from '@nestjs/common';
import { IdentityProvider, User, UserSession } from '@prisma/client';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { randomUUID } from 'crypto';
import { PrismaService } from '../common/prisma.service';

type DeviceMeta = {
  deviceId?: string;
  deviceName?: string;
  ipAddress?: string;
};

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async guestLogin(meta: DeviceMeta) {
    const providerUserId = meta.deviceId || `guest:${randomUUID()}`;
    const identity = await this.prisma.userIdentity.findUnique({
      where: {
        provider_providerUserId: {
          provider: IdentityProvider.GUEST,
          providerUserId,
        },
      },
      include: { user: true },
    });

    const user = identity?.user ?? await this.prisma.user.create({
      data: {
        identities: {
          create: {
            provider: IdentityProvider.GUEST,
            providerUserId,
          },
        },
      },
    });

    return this.issueTokens(user, meta);
  }

  async appleLogin(identityToken: string, meta: DeviceMeta) {
    const appleSub = this.extractAppleSubject(identityToken);
    const identity = await this.prisma.userIdentity.findUnique({
      where: {
        provider_providerUserId: {
          provider: IdentityProvider.APPLE,
          providerUserId: appleSub,
        },
      },
      include: { user: true },
    });

    const user = identity?.user ?? await this.prisma.user.create({
      data: {
        identities: {
          create: {
            provider: IdentityProvider.APPLE,
            providerUserId: appleSub,
          },
        },
      },
    });

    return this.issueTokens(user, meta);
  }

  async refresh(refreshToken: string) {
    let payload: { sub: string; sessionId: string };
    try {
      payload = await this.jwt.verifyAsync(refreshToken, {
        secret: process.env.JWT_REFRESH_SECRET || 'dev_refresh_secret',
      });
    } catch {
      throw new UnauthorizedException('invalid refresh token');
    }

    const session = await this.prisma.userSession.findUnique({
      where: { id: payload.sessionId },
      include: { user: true },
    });
    if (!session || session.revokedAt || session.expiresAt < new Date()) {
      throw new UnauthorizedException('expired refresh token');
    }

    const ok = await bcrypt.compare(refreshToken, session.refreshTokenHash);
    if (!ok) throw new UnauthorizedException('invalid refresh token');

    return this.issueAccessToken(session.user, session);
  }

  async revokeSession(userId: string, sessionId?: string) {
    if (!sessionId) return { ok: true };
    await this.prisma.userSession.updateMany({
      where: { id: sessionId, userId },
      data: { revokedAt: new Date() },
    });
    return { ok: true };
  }

  private async issueTokens(user: User, meta: DeviceMeta) {
    const session = await this.prisma.userSession.create({
      data: {
        userId: user.id,
        refreshTokenHash: '',
        deviceId: meta.deviceId,
        deviceName: meta.deviceName,
        ipAddress: meta.ipAddress,
        expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 60),
      },
    });
    const accessToken = await this.signAccessToken(user, session);
    const refreshToken = await this.signRefreshToken(user, session);
    await this.prisma.userSession.update({
      where: { id: session.id },
      data: { refreshTokenHash: await bcrypt.hash(refreshToken, 10) },
    });
    return { user: this.publicUser(user), accessToken, refreshToken };
  }

  private async issueAccessToken(user: User, session: UserSession) {
    return {
      accessToken: await this.signAccessToken(user, session),
      user: this.publicUser(user),
    };
  }

  private signAccessToken(user: User, session: UserSession) {
    return this.jwt.signAsync(
      { sub: user.id, sessionId: session.id },
      {
        secret: process.env.JWT_ACCESS_SECRET || 'dev_access_secret',
        expiresIn: '15m',
      },
    );
  }

  private signRefreshToken(user: User, session: UserSession) {
    return this.jwt.signAsync(
      { sub: user.id, sessionId: session.id },
      {
        secret: process.env.JWT_REFRESH_SECRET || 'dev_refresh_secret',
        expiresIn: '60d',
      },
    );
  }

  private publicUser(user: User) {
    return {
      id: user.id,
      status: user.status,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      avatarSymbol: user.avatarSymbol,
      background: user.background,
      signature: user.signature,
      coins: user.coins,
      level: user.level,
      totalScore: user.totalScore,
      totalGames: user.totalGames,
    };
  }

  private extractAppleSubject(identityToken: string) {
    if (process.env.NODE_ENV === 'production' && process.env.APPLE_LOGIN_DEV_MODE !== 'true') {
      throw new UnauthorizedException('apple token verifier is not configured');
    }
    const parts = identityToken.split('.');
    if (parts.length < 2) {
      throw new UnauthorizedException('invalid apple token');
    }
    try {
      const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8')) as { sub?: string; aud?: string; exp?: number };
      if (!payload.sub) throw new Error('missing sub');
      if (payload.exp && payload.exp * 1000 < Date.now()) throw new Error('expired token');
      return payload.sub;
    } catch {
      throw new UnauthorizedException('invalid apple token');
    }
  }
}
