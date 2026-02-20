import { Injectable, UnauthorizedException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
    constructor(
        private usersService: UsersService,
        private jwtService: JwtService,
    ) { }

    /**
     * Validasi user untuk login
     * @param email Email user
     * @param pass Password plain text
     */
    async validateUser(email: string, pass: string): Promise<any> {
        const user = await this.usersService.findByEmail(email);
        // Catatan: Pada schema database asli menggunakan Supabase Auth
        // Di sini kita asumsikan ada filed password (meskipun di schema prisma user belum ada)
        // Untuk pengembangan mandiri, kita perlu menambahkan field password di table users
        if (user && await bcrypt.compare(pass, (user as any).password)) {
            const { password, ...result } = user as any;
            return result;
        }
        return null;
    }

    /**
     * Proses Login dan generate Token
     * @param user Objek user yang sudah divalidasi
     */
    async login(user: any) {
        const payload = { email: user.email, sub: user.id, role: user.role };
        return {
            access_token: this.jwtService.sign(payload),
            user: user,
        };
    }

    /**
     * Registrasi user baru
     * @param data Data registrasi
     */
    async register(data: any) {
        const hashedPassword = await bcrypt.hash(data.password, 10);
        const { password, ...userData } = data;

        return this.usersService.create({
            ...userData,
            password: hashedPassword, // Kita asumsikan field ini ada di DB
        } as any);
    }
}
