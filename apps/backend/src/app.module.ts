import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { NotesModule } from './notes/notes.module';

// Log database configuration for debugging
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 5432,
  username: process.env.DB_USERNAME || 'dbadmin',
  database: process.env.DB_NAME || 'appdb',
};
console.log('Database configuration:', dbConfig);

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: dbConfig.host,
      port: dbConfig.port,
      username: dbConfig.username,
      password: process.env.DB_PASSWORD || 'changeme',
      database: dbConfig.database,
      autoLoadEntities: true,
      synchronize: true,
      ssl: process.env.DB_SSL === 'true' ? {
        rejectUnauthorized: false
      } : false,
      // Add retry logic for container startup
      retryAttempts: 10,
      retryDelay: 3000,
      // Log queries for debugging
      logging: process.env.NODE_ENV !== 'production' ? true : ['error', 'warn'],
    }),
    NotesModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
