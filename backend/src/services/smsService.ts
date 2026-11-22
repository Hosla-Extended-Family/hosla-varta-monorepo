import config from '../config';
import logger from '../utils/logger';

export class SmsService {

    static async sendOtp(phone: string, otp: string, expiry?: number): Promise<boolean> {
        const { provider } = config.sms;

        try {
            switch (provider) {
                case 'fast2sms':
                    return await this.sendFast2Sms(phone, otp, expiry);
              
                default:
                    logger.warn(`SMS provider ${provider} not implemented. Falling back to mock.`);
                    return true;
            }
        } catch (error) {
            logger.error('Error in sendOtp:', error);
            return false;
        }
    }

 
    private static async sendFast2Sms(phone: string, otp: string, expiry?: number): Promise<boolean> {
        const { apiKey, entityId, senderId, templateId } = config.sms.fast2sms;

        if (!apiKey) {
            logger.error('Fast2SMS API Key is missing');
            return false;
        }

        const cleanPhone = phone.replace(/^\+91/, '').replace(/\D/g, '');

        const url = 'https://www.fast2sms.com/dev/bulkV2';

        const variables_values = otp;
        
        const body = {
            route: 'dlt',
            sender_id: senderId,
            message: templateId,
            variables_values,
            numbers: cleanPhone,
            flash: 0,
            entity_id: entityId
        };

        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'authorization': apiKey,
                    'Content-Type': 'application/json',
                    'accept': 'application/json'
                },
                body: JSON.stringify(body)
            });

            const result = await response.json() as any;

            if (response.ok && result.return === true) {
                logger.info(`Fast2SMS: OTP sent successfully to ${cleanPhone}. Request ID: ${result.request_id}`);
                return true;
            } else {
                logger.error('Fast2SMS: Error sending SMS', result);
                return false;
            }
        } catch (error) {
            logger.error('Fast2SMS: Network error or parse error', error);
            throw error;
        }
    }
}
