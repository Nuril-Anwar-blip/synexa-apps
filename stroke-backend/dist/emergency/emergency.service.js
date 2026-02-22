"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.EmergencyService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let EmergencyService = class EmergencyService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async create(data) {
        return this.prisma.emergencyLog.create({
            data: {
                user_id: data.user_id,
                location_lat: data.location_lat,
                location_long: data.location_long,
                status: 'active',
            },
        });
    }
    async updateStatus(id, status) {
        return this.prisma.emergencyLog.update({
            where: { id },
            data: { status },
        });
    }
    async findAll() {
        return this.prisma.emergencyLog.findMany({
            include: { user: { select: { full_name: true, phone_number: true } } },
            orderBy: { triggered_at: 'desc' },
        });
    }
    async findByUser(userId) {
        return this.prisma.emergencyLog.findMany({
            where: { user_id: userId },
            orderBy: { triggered_at: 'desc' },
        });
    }
};
exports.EmergencyService = EmergencyService;
exports.EmergencyService = EmergencyService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], EmergencyService);
//# sourceMappingURL=emergency.service.js.map