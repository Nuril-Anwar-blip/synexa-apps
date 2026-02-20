import { Controller, Post, Body, UseGuards, Request, Get } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
    constructor(private authService: AuthService) { }

    /**
     * Endpoint Registrasi
     * @param body Data registrasi dari client
     */
    @Post('register')
    async register(@Body() body: any) {
        return this.authService.register(body);
    }

    /**
     * Endpoint Login
     * @param body Data login (email, password)
     */
    @Post('login')
    async login(@Body() body: any) {
        // Sederhananya validasi manual di sini untuk demo
        const user = await this.authService.validateUser(body.email, body.password);
        if (!user) {
            throw new UnauthorizedException('Email atau password salah');
        }
        return this.authService.login(user);
    }
}

// Helper UnauthorizedException manual jika nestjs error
class UnauthorizedException extends Error {
    constructor(message: string) {
        super(message);
        this.name = 'UnauthorizedException';
    }
}
