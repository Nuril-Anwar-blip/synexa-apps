import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MedicationReminder, Prisma } from '@prisma/client';

@Injectable()
export class MedicationService {
    constructor(private prisma: PrismaService) { }

    /**
     * Mengambil semua pengingat obat untuk user tertentu
     * @param userId ID user
     */
    async findAllByUser(userId: string): Promise<MedicationReminder[]> {
        return this.prisma.medicationReminder.findMany({
            where: { user_id: userId },
            orderBy: { time: 'asc' },
        });
    }

    /**
     * Membuat pengingat obat baru
     * @param data Data pengingat obat
     */
    async create(data: Prisma.MedicationReminderCreateInput): Promise<MedicationReminder> {
        return this.prisma.medicationReminder.create({
            data,
        });
    }

    /**
     * Mencatat obat telah diminum dan memperbarui stok
     * @param id ID pengingat obat
     */
    async markAsTaken(id: string): Promise<MedicationReminder> {
        const reminder = await this.prisma.medicationReminder.findUnique({ where: { id } });
        if (!reminder) throw new Error('Pengingat tidak ditemukan');

        return this.prisma.medicationReminder.update({
            where: { id },
            data: {
                taken: true,
                current_stock: {
                    decrement: 1, // Asumsi 1 dosis = 1 stok
                },
            },
        });
    }

    /**
     * Memperbarui stok obat
     * @param id ID pengingat obat
     * @param amount Jumlah stok baru yang ditambahkan
     */
    async updateStock(id: string, amount: number): Promise<MedicationReminder> {
        return this.prisma.medicationReminder.update({
            where: { id },
            data: {
                total_stock: {
                    increment: amount,
                },
                current_stock: {
                    increment: amount,
                },
            },
        });
    }
}
