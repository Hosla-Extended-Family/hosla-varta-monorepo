
export const normalizePhone = (phone: string): string => {
    // Remove all non-digit characters
    const digits = phone.replace(/\D/g, '');

    // If it's a 10-digit number, assume Indian and prepend +91
    if (digits.length === 10) {
        return `+91${digits}`;
    }

    // If it's 12 digits and starts with 91, ensure it has + prefix
    if (digits.length === 12 && digits.startsWith('91')) {
        return `+${digits}`;
    }

    // For other cases, return original or try to format? 
    // For now, return original if it doesn't match expected Indian format logic, 
    // or arguably return '+' + digits if it looks like an international number without +
    // But strictly following the user's "keep indian number" request:

    return phone.startsWith('+') ? phone : `+${digits}`;
};
