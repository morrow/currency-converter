// Generated by CoffeeScript 1.8.0
var Converter;

Converter = (function() {
  Converter.prototype.CONFIGURATION = {
    conversion_keypress_delay: 500,
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
    this.include_commission = $('#commission input').prop('checked');
    this.remote_currency = this.CONFIGURATION.currencies_enabled_remote[0];
    this.local_currency = this.CONFIGURATION.currencies_enabled_local[0];
    this.updateExchangeRates((function(_this) {
      return function() {
        return _this.convert();
      };
    })(this));
    this.populateSelectOptions();
    this.listen();
  }

  Converter.prototype.populateSelectOptions = function() {
    var currency, currency_data, _i, _len, _ref;
    if ($('#remote-country select').text() === '') {
      _ref = this.CONFIGURATION.currencies_enabled_remote;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        currency = _ref[_i];
        currency_data = this.CURRENCY_DATA[currency];
        $('#remote-country select').append("<option value='" + currency + "'>" + currency_data.country + "</option>");
      }
    }
    $('#currency select').html('');
    $('#currency select').append("<option value='" + this.local_currency + "'>" + this.local_currency + "</option>");
    if (this.local_currency !== 'USD' && this.remote_currency !== 'USD') {
      $('#currency select').append("<option value='USD'>USD</option>");
    }
    $('#currency select').append("<option value='" + this.remote_currency + "'>" + this.remote_currency + "</option>");
    return $('#currency select').change();
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
    if ($('#input').val() === '') {
      return false;
    }
    input = this.parseNum($('#input').val());
    currency = $('#currency select').val();
    if (currency === this.remote_currency) {
      $('#commission input').prop('checked', 'checked');
      $('#commission, #commission input').attr('disabled', 'disabled');
      $('#commission').addClass('disabled');
      $('#commission').attr('title', 'Commission is always included for this transaction type');
      this.include_commission = true;
    } else {
      $('#commission').removeClass('disabled');
      $('#commission, #commission input').removeAttr('disabled');
      $('#commission').removeAttr('title');
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
      commission = this.getCommission(remote_value);
      local_value = remote_value * this.rates[this.remote_currency];
      if (this.include_commission) {
        local_value += commission;
      }
    } else {
      local_value = input;
      local_value = input * this.rates[currency];
      commission = this.getCommission(local_value);
      if (this.include_commission) {
        local_value -= commission;
      }
      remote_value = local_value / this.rates[this.remote_currency];
    }
    $('#amount').text(this.format(local_value, this.local_currency));
    $('#amount').attr('data-currency', this.local_currency);
    $('#amount').attr('data-amount', local_value);
    $('#fees').text(this.format(commission, this.local_currency));
    $('#fees').attr('data-currency', this.local_currency);
    $('#fees').attr('data-amount', commission);
    $('#total-due').text(this.format(local_value + commission, this.local_currency));
    $('#total-due').attr('data-currency', this.local_currency);
    $('#total-due').attr('data-amount', local_value + commission);
    $('#recipient-receives').text(this.format(remote_value), this.remote_currency);
    $('.local-currency').text(this.local_currency);
    $('.local-currency-flag').attr('src', "./flags/png/" + this.local_currency + ".png");
    $('.local-currency-symbol').text(this.CURRENCY_DATA[this.local_currency].symbol);
    $('.remote-currency').text(this.remote_currency);
    $('.remote-currency-flag').attr('src', "./flags/png/" + this.remote_currency + ".png");
    $('.remote-currency-symbol').text(this.CURRENCY_DATA[this.remote_currency].symbol);
    $('.conversion-rate').text(this.format(1 / this.rates[this.remote_currency], this.remote_currency, 4));
    $('.us-rate').each((function(_this) {
      return function(i, ele) {
        var amount;
        amount = _this.parseNum($(ele).siblings('.amount').attr('data-amount'));
        currency = $(ele).siblings('.amount').data('currency');
        return $(ele).find('.amount').text(_this.format(amount / _this.rates['USD']), 'USD');
      };
    })(this));
    if (this.include_us_rates) {
      $('.us-rate').show();
    } else {
      $('.us-rate').hide();
    }
    $('dd.fees .us-rate, dd.amount-to-send .us-rate').show();
    if ($('#input').val() === '') {
      $('#result').removeClass('expanded');
      return $('#info').hide();
    } else {
      $('#result').addClass('expanded');
      return $('#info').show();
    }
  };

  Converter.prototype.selectHandler = function(select_id, value) {
    var span_text;
    switch (select_id) {
      case 'remote-country':
        $('#remote-country-flag').attr('src', "./flags/png/" + value + ".png");
        span_text = this.CURRENCY_DATA[value]['country'];
        $('#currency select').val(value);
        this.selectHandler('currency', value);
        this.populateSelectOptions();
        break;
      case 'currency':
        this.include_us_rates = false;
        if (value === 'AUD') {
          this.remote_currency = $('#remote-country select').val();
        } else if (value === 'USD' && $('#remote-country select').val() !== 'USD') {
          this.include_us_rates = true;
        } else {
          this.remote_currency = value;
        }
        span_text = value;
        this.convert();
    }
    return $("#" + select_id + " select").siblings('span').text(span_text);
  };

  Converter.prototype.listen = function() {
    this.listening = true;
    $('#include-commission').on('change', (function(_this) {
      return function(e) {
        _this.include_commission = $(e.target).is(":checked");
        return _this.convert();
      };
    })(this));
    $('.select select').on('change', (function(_this) {
      return function(e) {
        _this.selectHandler($(e.target).parents('div').attr('id'), $(e.target).val());
        return _this.convert();
      };
    })(this));
    $('#input').on('keyup', (function(_this) {
      return function(e) {
        var delay;
        if (e.target.value === '') {
          delay = 0;
        } else {
          delay = _this.CONFIGURATION.conversion_keypress_delay;
        }
        window.clearTimeout(window.keyboard_timeout);
        if (_this.CONFIGURATION.continually_update_rates) {
          return window.keyboard_timeout = window.setTimeout((function() {
            return _this.updateExchangeRates(function() {
              return _this.convert();
            });
          }), delay);
        } else {
          return window.keyboard_timeout = window.setTimeout((function() {
            return _this.convert();
          }), delay);
        }
      };
    })(this));
    return $('.select select').change();
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

  Converter.prototype.updateExchangeRates = function(callback) {
    var currencies_to_convert, currency, url, _i, _len, _ref;
    if (!this.rates) {
      this.rates = {};
    }
    this.rates[this.local_currency] = 1;
    currencies_to_convert = [];
    _ref = this.CONFIGURATION.currencies_enabled_remote;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      currency = _ref[_i];
      currencies_to_convert.push(currency + this.local_currency);
    }
    url = 'https://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.xchange where pair in ( "' + currencies_to_convert.join('", "') + '" )&env=store://datatables.org/alltableswithkeys&format=json';
    return $.get(url, (function(_this) {
      return function(r) {
        var d, date, rate, time, _j, _len1, _ref1;
        time = '';
        date = '';
        _ref1 = r.query.results.rate;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          rate = _ref1[_j];
          _this.rates[rate.id.replace(_this.local_currency, '')] = rate.Rate;
          date = rate.Date;
          time = parseInt(rate.Time);
          time -= (new Date().getTimezoneOffset() - 5 * 60) / 60;
          if (rate.Time.match(/pm/i)) {
            time += 12;
          }
          time = "" + time + ":" + (parseInt(rate.Time.split(':')[1]));
        }
        d = new Date("" + date + " " + time).toLocaleString(navigator.language, {
          month: '2-digit',
          year: '2-digit',
          day: '2-digit',
          hour: '2-digit',
          minute: '2-digit'
        });
        $('#rates-updated-at').html("" + d + " from <a target='_blank' href='" + url + "'>yahoo finance</a>");
        if (callback) {
          return callback();
        }
      };
    })(this));
  };

  return Converter;

})();
