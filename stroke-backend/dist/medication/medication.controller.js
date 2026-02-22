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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MedicationController = void 0;
const common_1 = require("@nestjs/common");
const medication_service_1 = require("./medication.service");
const client_1 = require("@prisma/client");
let MedicationController = class MedicationController {
    medicationService;
    constructor(medicationService) {
        this.medicationService = medicationService;
    }
    async findAllByUser(userId) {
        return this.medicationService.findAllByUser(userId);
    }
    async create(data) {
        return this.medicationService.create(data);
    }
    async markAsTaken(id) {
        return this.medicationService.markAsTaken(id);
    }
    async updateStock(id, amount) {
        return this.medicationService.updateStock(id, amount);
    }
};
exports.MedicationController = MedicationController;
__decorate([
    (0, common_1.Get)('user/:userId'),
    __param(0, (0, common_1.Param)('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], MedicationController.prototype, "findAllByUser", null);
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], MedicationController.prototype, "create", null);
__decorate([
    (0, common_1.Patch)(':id/taken'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], MedicationController.prototype, "markAsTaken", null);
__decorate([
    (0, common_1.Patch)(':id/stock'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)('amount')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Number]),
    __metadata("design:returntype", Promise)
], MedicationController.prototype, "updateStock", null);
exports.MedicationController = MedicationController = __decorate([
    (0, common_1.Controller)('medication'),
    __metadata("design:paramtypes", [medication_service_1.MedicationService])
], MedicationController);
//# sourceMappingURL=medication.controller.js.map