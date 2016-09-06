// Generated by CoffeeScript 1.8.0
var Converter,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Converter = (function() {
  Converter.prototype.CONFIGURATION = {
    conversion_keypress_delay: 10,
    significant_digits: 2,
    continually_update_rates: false,
    currencies_enabled_remote: ['USD', 'ETB', 'EGP', 'SDG', 'KES'],
    currencies_enabled_local: ['AUD']
  };

  Converter.prototype.CURRENCY_DATA = {
    'USD': {
      'name': 'U.S. Dollar',
      'symbol': '$',
      'locale': 'en-US',
      'country': 'United States'
    },
    'AUD': {
      'name': 'Australian Dollar',
      'symbol': '$',
      'locale': 'en-AU',
      'country': 'Australia'
    },
    'ETB': {
      'name': 'Ethiopian Birr',
      'symbol': 'Br',
      'locale': 'am-ET',
      'country': 'Ethiopia'
    },
    'EGP': {
      'name': 'Egyptian Pound',
      'symbol': 'E£',
      'locale': 'ar-EG',
      'country': 'Egypt'
    },
    'SDG': {
      'name': 'Sudanese Pound',
      'symbol': 'SDG',
      'locale': 'ar-SU',
      'country': 'Sudan'
    },
    'KES': {
      'name': 'Kenyan Shilling',
      'symbol': 'KSh',
      'locale': 'sw-KE',
      'country': 'Kenya'
    }
  };

  function Converter() {
    this.checkboxHandler = __bind(this.checkboxHandler, this);
    this.rates = window.converter_exchange_rates;
    this.include_commission = $('#converter #commission input').prop('checked');
    this.remote_currency = this.CONFIGURATION.currencies_enabled_remote[0];
    this.local_currency = this.CONFIGURATION.currencies_enabled_local[0];
    this.populateSelectOptions();
    this.listen();
  }

  Converter.prototype.listen = function() {
    this.listening = true;
    $('#converter #include-commission').on('change', (function(_this) {
      return function(e) {
        return _this.checkboxHandler($('#converter #include-commission').is(':checked'));
      };
    })(this));
    $('#converter .select select').on('change', (function(_this) {
      return function(e) {
        return _this.selectHandler($(e.target).parents('div').attr('id'), $(e.target).val());
      };
    })(this));
    $('#converter #input').on('input', (function(_this) {
      return function(e) {
        return _this.inputHandler(e.target.value);
      };
    })(this));
    return $('#converter .select select').change();
  };

  Converter.prototype.populateSelectOptions = function() {
    var currency, currency_data, _i, _len, _ref;
    if ($('#converter #remote-country select').text() === '') {
      _ref = this.CONFIGURATION.currencies_enabled_remote;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        currency = _ref[_i];
        currency_data = this.CURRENCY_DATA[currency];
        $('#converter #remote-country select').append("<option value='" + currency + "'>" + currency_data.country + "</option>");
      }
    }
    $('#converter #currency select').html('');
    $('#converter #currency select').append("<option value='" + this.local_currency + "'>" + this.local_currency + "</option>");
    if (this.local_currency !== 'USD' && this.remote_currency !== 'USD') {
      $('#converter #currency select').append("<option value='USD'>USD</option>");
    }
    $('#converter #currency select').append("<option value='" + this.remote_currency + "'>" + this.remote_currency + "</option>");
    return $('#converter #currency select').change();
  };

  Converter.prototype.getCommission = function(amount) {
    amount = this.parseNum(amount);
    this.commission_rate = 0.05;
    if (amount >= 1000) {
      this.commission_rate = 0.04;
    }
    if (amount >= 3000) {
      this.commission_rate = 0.03;
    }
    if (amount >= 4000) {
      this.commission_rate = 0.02;
    }
    if (amount >= 5000) {
      this.commission_rate = 0.02;
    }
    return amount * this.commission_rate;
  };

  Converter.prototype.convert = function() {
    var commission, currency, input, local_value, remote_value;
    input = this.parseNum($('#converter #input').val());
    currency = $('#converter #currency select').val();
    if (currency === this.remote_currency) {
      this.include_commission = true;
      $('#converter #commission input').prop('checked', 'checked');
      $('#converter #commission, #commission input').attr('disabled', 'disabled');
      $('#converter #commission').addClass('disabled');
      $('#converter #commission').attr('title', 'Commission is always included for this transaction type');
    } else {
      $('#converter #commission').removeClass('disabled');
      $('#converter #commission, #commission input').removeAttr('disabled');
      $('#converter #commission').removeAttr('title');
    }
    if (currency === 'AUD') {
      local_value = input;
      commission = this.getCommission(local_value);
      if (this.include_commission) {
        local_value -= commission;
      }
      remote_value = local_value / this.rates[this.remote_currency];
    } else if (currency === this.remote_currency) {
      remote_value = input;
      commission = this.getCommission(remote_value * this.rates[this.remote_currency]);
      local_value = remote_value * this.rates[this.remote_currency];
    } else {
      local_value = input * this.rates[currency];
      commission = this.getCommission(local_value);
      if (this.include_commission) {
        local_value -= commission;
      }
      remote_value = local_value / this.rates[this.remote_currency];
    }
    $('#converter #amount').text(this.format(local_value, this.local_currency));
    $('#converter #amount').attr('data-currency', this.local_currency);
    $('#converter #amount').attr('data-amount', local_value);
    $('#converter #fees').text(this.format(commission, this.local_currency));
    $('#converter #fees').attr('data-currency', this.local_currency);
    $('#converter #fees').attr('data-amount', commission);
    $('#converter #total-due').text(this.format(local_value + commission, this.local_currency));
    $('#converter #total-due').attr('data-currency', this.local_currency);
    $('#converter #total-due').attr('data-amount', local_value + commission);
    $('#converter #recipient-receives').text(this.format(remote_value), this.remote_currency);
    $('#converter .local-currency').text(this.local_currency);
    $('#converter .local-currency-flag').attr('src', "./flags/png/" + this.local_currency + ".png");
    $('#converter .local-currency-symbol').text(this.CURRENCY_DATA[this.local_currency].symbol);
    $('#converter .remote-currency').text(this.remote_currency);
    $('#converter .remote-currency-flag').attr('src', "./flags/png/" + this.remote_currency + ".png");
    $('#converter .remote-currency-symbol').text(this.CURRENCY_DATA[this.remote_currency].symbol);
    $('#converter .conversion-rate').text(this.format(1 / this.rates[this.remote_currency], this.remote_currency, 4));
    $('#converter .us-rate').each((function(_this) {
      return function(i, ele) {
        var amount;
        amount = _this.parseNum($(ele).siblings('.amount').attr('data-amount'));
        currency = $(ele).siblings('.amount').data('currency');
        return $(ele).find('.amount').text(_this.format(amount / _this.rates['USD']), 'USD');
      };
    })(this));
    if (this.include_us_rates) {
      $('#converter .us-rate').show();
    } else {
      $('#converter .us-rate').hide();
    }
    $('#converter dd.fees .us-rate, dd.amount-to-send .us-rate').show();
    if ($('#converter #input').val() === '') {
      $('#converter #result').removeClass('expanded');
      return $('#converter #info').hide();
    } else {
      $('#converter #result').addClass('expanded');
      return $('#converter #info').show();
    }
  };

  Converter.prototype.selectHandler = function(select_id, value) {
    var span_text;
    switch (select_id) {
      case 'remote-country':
        $('#converter #remote-country-flag').attr('src', "./flags/png/" + value + ".png");
        span_text = this.CURRENCY_DATA[value]['country'];
        $('#converter #currency select').val(value);
        this.selectHandler('currency', value);
        this.populateSelectOptions();
        break;
      case 'currency':
        this.include_us_rates = false;
        if (value === 'AUD') {
          this.remote_currency = $('#converter #remote-country select').val();
        } else if (value === 'USD' && $('#converter #remote-country select').val() !== 'USD') {
          this.include_us_rates = true;
        } else {
          this.remote_currency = value;
        }
        span_text = value;
        this.convert();
    }
    return $("#converter #" + select_id + " select").siblings('span').text(span_text);
  };

  Converter.prototype.checkboxHandler = function(bool) {
    this.include_commission = bool;
    return this.convert();
  };

  Converter.prototype.inputHandler = function(value) {
    var delay;
    if (value === '') {
      delay = 0;
    } else {
      delay = this.CONFIGURATION.conversion_keypress_delay;
    }
    window.clearTimeout(window.keypress_timeout);
    if (this.CONFIGURATION.continually_update_rates) {
      return window.keypress_timeout = window.setTimeout(((function(_this) {
        return function() {
          return _this.updateExchangeRates(function() {
            return _this.convert();
          });
        };
      })(this)), delay);
    } else {
      return window.keypress_timeout = window.setTimeout(((function(_this) {
        return function() {
          return _this.convert();
        };
      })(this)), delay);
    }
  };

  Converter.prototype.format = function(number, currency, significant_digits) {
    var parts;
    if (currency == null) {
      currency = 'USD';
    }
    if (significant_digits == null) {
      significant_digits = this.CONFIGURATION.significant_digits;
    }
    if (!!!number.toString().match(/[0-9]/)) {
      return '';
    }
    number = this.roundNum(number, significant_digits);
    parts = number.toString().split('.');
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    return parts.join('.');
  };

  Converter.prototype.parseNum = function(input) {
    if (!input || !input.toString().replace(/,|\./g, '').match(/[0-9]/)) {
      return '';
    }
    return parseFloat(parseFloat(input.toString().replace(/,/g, '')).toFixed(this.CONFIGURATION.significant_digits));
  };

  Converter.prototype.roundNum = function(number, significant_digits) {
    var rounder;
    if (significant_digits == null) {
      significant_digits = this.CONFIGURATION.significant_digits;
    }
    if (!number.toString().match(/[0-9]/)) {
      return '';
    }
    rounder = Math.pow(10, significant_digits);
    return (Math.round(number * rounder) / rounder).toFixed(significant_digits);
  };

  return Converter;

})();
