import redis from '../config/redis';
import config from '../config';
import logger from '../utils/logger';
import { JobType, addJob } from '../config/queue';
import bcryptjs from 'bcryptjs';

export class OtpService {
    private static readonly OTP_TTL = 300;

    static async generateOtp(phone: string): Promise<string | null> {
        let otp: string;

        if (config.env === 'development' && config.otp.useFixedOtp) {
            otp = config.otp.fixedOtpValue;
            logger.info(`DEV MODE: Using fixed OTP ${otp} for ${phone}`);
            // Still hash even in dev mode for consistency
            const hashedOtp = await bcryptjs.hash(otp, 10);
            const key = `otp:${phone}`;
            await redis.set(key, hashedOtp, 'EX', this.OTP_TTL);
            return otp; // Return plain OTP for dev logging
        } else {
            otp = Math.floor(100000 + Math.random() * 900000).toString();
        }

        // Hash OTP before storing in Redis
        const hashedOtp = await bcryptjs.hash(otp, 10);
        const key = `otp:${phone}`;
        await redis.set(key, hashedOtp, 'EX', this.OTP_TTL);

        // Queue job to send SMS with plain OTP (not hashed)
        await addJob(JobType.SEND_OTP, {
            phone,
            otp,
            expiry: Math.floor(this.OTP_TTL / 60),
        });

        return null;
    }

    static async verifyOtp(phone: string, otp: string): Promise<boolean> {
        const key = `otp:${phone}`;
        const hashedOtp = await redis.get(key);

        if (!hashedOtp) {
            logger.warn(`OTP verification failed: No OTP found for ${phone}`);
            return false;
        }

        // Compare using bcryptjs
        const isValid = await bcryptjs.compare(otp, hashedOtp);

        if (isValid) {
            // Delete OTP after successful verification
            await redis.del(key);
            logger.info(`OTP verification successful for ${phone}`);
            return true;
        }

        logger.warn(`OTP verification failed: Invalid OTP for ${phone}`);
        return false;
    }
}
