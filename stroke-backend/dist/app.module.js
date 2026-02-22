"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const app_controller_1 = require("./app.controller");
const app_service_1 = require("./app.service");
const auth_module_1 = require("./auth/auth.module");
const users_module_1 = require("./users/users.module");
const prisma_module_1 = require("./prisma/prisma.module");
const config_1 = require("@nestjs/config");
const medication_module_1 = require("./medication/medication.module");
const chat_module_1 = require("./chat/chat.module");
const community_module_1 = require("./community/community.module");
const sensor_module_1 = require("./sensor/sensor.module");
const education_module_1 = require("./education/education.module");
const emergency_module_1 = require("./emergency/emergency.module");
const health_module_1 = require("./health/health.module");
const rehab_module_1 = require("./rehab/rehab.module");
const notifications_module_1 = require("./notifications/notifications.module");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({ isGlobal: true }),
            prisma_module_1.PrismaModule,
            auth_module_1.AuthModule,
            users_module_1.UsersModule,
            medication_module_1.MedicationModule,
            chat_module_1.ChatModule,
            community_module_1.CommunityModule,
            sensor_module_1.SensorModule,
            education_module_1.EducationModule,
            emergency_module_1.EmergencyModule,
            health_module_1.HealthModule,
            rehab_module_1.RehabModule,
            notifications_module_1.NotificationsModule,
        ],
        controllers: [app_controller_1.AppController],
        providers: [app_service_1.AppService],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map