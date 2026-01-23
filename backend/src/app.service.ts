import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello(): string {
    return 'NestJS Backend API is running!';
  }

  getHealth(): object {
    return {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      service: 'backend-api',
      database: 'connected'
    };
  }

  getStatus(): object {
    return {
      version: '1.0.0',
      environment: process.env.NODE_ENV || 'production',
      uptime: process.uptime(),
      timestamp: new Date().toISOString()
    };
  }
}
