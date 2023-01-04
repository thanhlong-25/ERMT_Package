/**
 * 共通定義
 */

// データ型
export const TYPE_BOOLEAN = 'BOOLEAN';
export const TYPE_DATE = 'DATE';
export const TYPE_TIME = 'TIME';
export const TYPE_DATETIME = 'DATETIME';
export const TYPE_INTEGER = 'INTEGER';
export const TYPE_LONG = 'LONG';
export const TYPE_DOUBLE = 'DOUBLE';
export const TYPE_CURRENCY = 'CURRENCY';
export const TYPE_PERCENT = 'PERCENT';
export const TYPE_PICKLIST = 'PICKLIST';
export const TYPE_MULTIPICKLIST = 'MULTIPICKLIST';
export const TYPE_STRING = 'STRING';
export const TYPE_PHONE = 'PHONE';
export const TYPE_TEXTAREA = 'TEXTAREA';
export const TYPE_ID = 'ID';
export const TYPE_REFERENCE = 'REFERENCE';
export const TYPE_BASE64 = 'BASE64';
export const TYPE_ENCRYPTEDSTRING = 'ENCRYPTEDSTRING';
export const TYPE_DATACATEGORYGROUPREFERENCE = 'DATACATEGORYGROUPREFERENCE';

// 未定義からnullに変換
export function undefineToNull(value) {
    let ret = value;
    if (isUndefined(ret)) {
        ret = null;
    }
    return ret;
}

// 文字列から数値へ変換
export function stringToNumber(value) {
    let num = null;
    if (isString(value) && value !== '') {
        num = Number(value.replace(',', ''));
        if (isNaN(num)) {
            num = null;
        }
    } else if (isNumber(value)) {
        num = value;
    }
    return num;
}

// 数値をカンマ区切りの文字列に変換
export function formatNumber(value) {
    let num = null;
    if (isNumber(value)) {
        num = String(value);
        let dec = '';
        if (num.indexOf('.') >= 0) {
            let nums = num.split('.');
            num = nums[0];
            dec = nums[1];
        }
        num = num.replace(/(\d)(?=(\d{3})+$)/g , '$1,');
        if (dec) {
            dec = dec.replace(/0+$/, '');
            if (dec) {
                num += '.' + dec;
            }
        }
    } else if (isString(value)) {
        num = value;
    }
    return num;
}

// 日付フォーマット
export function formatDate(date, format) {
    const _fmt = {
        hh: function(date) { return ('0' + date.getHours()).slice(-2); },
        h: function(date) { return date.getHours(); },
        mm: function(date) { return ('0' + date.getMinutes()).slice(-2); },
        m: function(date) { return date.getMinutes(); },
        ss: function(date) { return ('0' + date.getSeconds()).slice(-2); },
        dd: function(date) { return ('0' + date.getDate()).slice(-2); },
        d: function(date) { return date.getDate(); },
        s: function(date) { return date.getSeconds(); },
        yyyy: function(date) { return date.getFullYear() + ''; },
        yy: function(date) { return date.getYear() + ''; },
        t: function(date) { return date.getDate()<=3 ? ["st", "nd", "rd"][date.getDate()-1]: 'th'; },
        w: function(date) {return ["Sun", "$on", "Tue", "Wed", "Thu", "Fri", "Sat"][date.getDay()]; },
        MMMM: function(date) { return ["January", "February", "$arch", "April", "$ay", "June", "July", "August", "September", "October", "November", "December"][date.getMonth()]; },
        MMM: function(date) {return ["Jan", "Feb", "$ar", "Apr", "$ay", "Jun", "Jly", "Aug", "Spt", "Oct", "Nov", "Dec"][date.getMonth()]; },  
        MM: function(date) { return ('0' + (date.getMonth() + 1)).slice(-2); },
        M: function(date) { return date.getMonth() + 1; },
        $: function(date) {return 'M';}
    };
    const _priority = ["hh", "h", "mm", "m", "ss", "dd", "d", "s", "yyyy", "yy", "t", "w", "MMMM", "MMM", "MM", "M", "$"];
    return _priority.reduce((res, fmt) => res.replace(fmt, _fmt[fmt](date)), format);
}

// 小数の切り捨て
export function roundDownDecimal(value, digit) {
    const base = Math.pow(10, digit);
    return Math.floor(value * base) / base;
}

// 小数の切り上げ
export function roundUpDecimal(value, digit) {
    const base = Math.pow(10, digit);
    return Math.ceil(value * base) / base;
}

// 小数の四捨五入
export function roundDecimal(value, digit) {
    const base = Math.pow(10, digit);
    return Math.round(value * base) / base;
}

// 未定義チェック
export function isUndefined(obj) {
    return Object.prototype.toString.call(obj).slice(8, -1).toLowerCase() === 'undefined';
}

// 数値チェック
export function isNumber(obj) {
    return Object.prototype.toString.call(obj).slice(8, -1).toLowerCase() === 'number';
}

// 文字列チェック
export function isString(obj) {
    return Object.prototype.toString.call(obj).slice(8, -1).toLowerCase() === 'string';
}

// 配列チェック
export function isArray(obj) {
    return Object.prototype.toString.call(obj).slice(8, -1).toLowerCase() === 'array';
}

// 連想配列チェック
export function isObject(obj) {
    return Object.prototype.toString.call(obj).slice(8, -1).toLowerCase() === 'object';
}

/**
 * エラーメッセージリストの取得
 * @param {FetchResponse|FetchResponse[]|String|String[]} errors
 * @return {String[]} Error messages
 */
export function getErrorMessages(errors) {
    if (!Array.isArray(errors)) {
        errors = [errors];
    }

    return (
        errors
            // Remove null/undefined items
            .filter((error) => !!error)
            // Extract an error message
            .map((error) => {
                // UI API read errors
                if (Array.isArray(error.body)) {
                    return error.body.map((e) => e.message);
                }
                // UI API DML, Apex and network errors
                else if (error.body && typeof error.body.message === 'string') {
                    return error.body.message;
                }
                // JS errors
                else if (typeof error.message === 'string') {
                    return error.message;
                }
                // ページエラー
                else if (error.body && Array.isArray(error.body.pageErrors) && error.body.pageErrors.length) {
                    return error.body.pageErrors.map((e) => e.message);
                }
                // Unknown error shape so try HTTP status text
                else if (typeof error.statusText === 'string') {
                    return error.statusText;
                }
                else if (typeof error === 'string') {
                    return error;
                }
                return '';
            })
            // Flatten
            .reduce((prev, curr) => prev.concat(curr), [])
            // Remove empty strings
            .filter((message) => !!message)
    );
}

// 背景色に対して文字色が黒か白か
// backgroundHexColor: 背景色 (例)#ffffff
export function getTextColorBlackOrWhite(backgroundHexColor) {
    let ret = 'black';
    if (backgroundHexColor) {
        const r = parseInt(backgroundHexColor.substr(1, 2), 16);
        const g = parseInt(backgroundHexColor.substr(3, 2), 16);
        const b = parseInt(backgroundHexColor.substr(5, 2), 16);
        if ((((r * 299) + (g * 587) + (b * 114)) / 1000) < 128) {
            ret = 'white';
        }
    }
    return ret;
}

// 項目値の取得
export function getFieldValue(record, fieldName) {
    let ret = null;
    let data = record;
    const names = (!fieldName ? [] : fieldName.split('.'));
    const nameLen = names.length;
    let name;
    for (let i = 0, len = nameLen - 1; i < len; i++) {
        if (!data) break;
        name = names[i];
        data = data[name];
    }
    if (data && nameLen > 0) {
        name = names[nameLen - 1];
        ret = undefineToNull(data[name]);
    }
    return ret;
}