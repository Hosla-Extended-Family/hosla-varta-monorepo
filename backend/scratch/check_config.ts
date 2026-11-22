import config from '../src/config';
console.log('SMS Provider:', config.sms.provider);
console.log('Fast2SMS Sender:', config.sms.fast2sms.senderId);
console.log('Fixed OTP:', config.otp.useFixedOtp);
