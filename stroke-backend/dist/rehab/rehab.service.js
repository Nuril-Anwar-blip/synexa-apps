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
exports.RehabService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let RehabService = class RehabService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getPhases() {
        return this.prisma.rehabPhase.findMany({
            orderBy: { order_index: 'asc' },
        });
    }
    async getExercises(phaseId) {
        return this.prisma.rehabExercise.findMany({
            where: { phase_id: phaseId },
            orderBy: { order_index: 'asc' },
        });
    }
    async logExercise(data) {
        return this.prisma.rehabExerciseLog.create({
            data,
        });
    }
    async getQuizQuestions(phaseId) {
        return this.prisma.rehabQuizQuestion.findMany({
            where: { from_phase_id: phaseId },
        });
    }
    async submitQuiz(data) {
        const responsesValue = data.responses;
        const attempt = await this.prisma.rehabQuizAttempt.create({
            data: {
                user_id: data.user_id,
                from_phase_id: data.phase_id,
                responses: responsesValue,
                score: 100,
                passed: true,
            },
        });
        await this.prisma.rehabUserProgress.upsert({
            where: { user_id: data.user_id },
            update: {
                current_phase_id: { increment: 1 },
                last_quiz_at: new Date(),
            },
            create: {
                user_id: data.user_id,
                current_phase_id: data.phase_id + 1,
                last_quiz_at: new Date(),
            },
        });
        return attempt;
    }
    async getUserProgress(userId) {
        const progress = await this.prisma.rehabUserProgress.findUnique({
            where: { user_id: userId },
            include: { phase: true },
        });
        if (!progress)
            throw new common_1.NotFoundException('Progress tidak ditemukan');
        return progress;
    }
};
exports.RehabService = RehabService;
exports.RehabService = RehabService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], RehabService);
//# sourceMappingURL=rehab.service.js.map