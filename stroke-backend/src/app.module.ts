import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { PrismaModule } from './prisma/prisma.module';
import { ConfigModule } from '@nestjs/config';
import { MedicationModule } from './medication/medication.module';
import { ChatModule } from './chat/chat.module';
import { CommunityModule } from './community/community.module';
import { SensorModule } from './sensor/sensor.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    UsersModule,
    MedicationModule,
    ChatModule,
    CommunityModule,
    SensorModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }
