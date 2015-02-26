class Converter

  CONFIGURATION:
    # conversion keypress delay - time in milliseconds to wait after keypress before converting
    conversion_keypress_delay: 500
    # number of decimal places to calculate conversions to
    significant_digits: 2
    # update exchange rates for each transaction - rate limit for YQL is 2,000 calls per hour
    continually_update_rates: false
    # currencies available to send remotely, first is default
    currencies_enabled_remote: ['USD', 'ETB', 'EGP', 'SDG', 'KES']
    # currencies available to pay locally, first is default
    currencies_enabled_local: ['AUD']

  CURRENCY_DATA: 
    'USD': 
      'name':   'U.S. Dollar'
      'symbol': '$'
      'locale': 'en-US'
      'country': 'United States'
    'AUD': 
      'name':   'Australian Dollar'
      'symbol': '$'
      'locale': 'en-AU'
      'country': 'Australia'
    'ETB': 
      'name':   'Ethiopian Birr'
      'symbol': 'Br'
      'locale': 'am-ET'
      'country': 'Ethiopia'
    'EGP': 
      'name':   'Egyptian Pound'
      'symbol': 'E£'
      'locale': 'ar-EG'
      'country': 'Egypt'
    'SDG': 
      'name':   'Sudanese Pound'
      'symbol': 'SDG'
      'locale': 'ar-SU'
      'country': 'Sudan'
    'KES': 
      'name':   'Kenyan Shilling'
      'symbol': 'KSh'
      'locale': 'sw-KE'
      'country': 'Kenya'

  # constructor
  constructor: ->
    # include commission by default
    @include_commission = $('#commission input').prop('checked')
    # get default remote currency
    @remote_currency = @CONFIGURATION.currencies_enabled_remote[0]
    # get default local currency
    @local_currency = @CONFIGURATION.currencies_enabled_local[0]
    # update exchange rates from external source
    @updateExchangeRates( => @convert() )
    # create dropdowns
    @populateSelectOptions()
    # listen for input changes
    @listen()

  # populate select options
  populateSelectOptions: ->
    # populate country options once only
    if $('#remote-country select').text() == ''
      for currency in @CONFIGURATION.currencies_enabled_remote
        currency_data = @CURRENCY_DATA[currency]
        $('#remote-country select').append( "<option value='#{currency}'>#{currency_data.country}</option>" )
    # populate currency select
    $('#currency select').html('')
    $('#currency select').append( "<option value='#{@local_currency}'>#{@local_currency}</option>" )
    $('#currency select').append( "<option value='USD'>USD</option>" ) if @local_currency != 'USD' and @remote_currency != 'USD'
    $('#currency select').append( "<option value='#{@remote_currency}'>#{@remote_currency}</option>" )
    # trigger on change event for currency select
    $('#currency select').change()

  # return comission rate for given value
  getCommission: ( amount )->
    amount = @parseNum( amount )
    @commission_rate = 0.05
    @commission_rate = 0.04 if amount >= 1000
    @commission_rate = 0.03 if amount >= 3000
    @commission_rate = 0.02 if amount >= 4000
    @commission_rate = 0.02 if amount >= 5000 # negotiable
    return amount * @commission_rate

  # convert
  convert: ->
    return false if $('#input').val() == ''
    input = @parseNum( $('#input').val() )
    currency = $('#currency select').val()
    if currency == @remote_currency
      $('#commission input').prop('checked', 'checked')
      $('#commission, #commission input').attr('disabled', 'disabled')
      $('#commission').addClass('disabled')
      $('#commission').attr('title', 'Commission is always included for this transaction type')
      @include_commission = true
    else
      $('#commission').removeClass('disabled')
      $('#commission, #commission input').removeAttr('disabled')
      $('#commission').removeAttr('title')
    if currency == 'AUD'
      local_value = input
      commission = @getCommission( local_value )
      local_value -= commission if @include_commission
      remote_value = local_value / @rates[@remote_currency]
    else if currency == @remote_currency
      remote_value = input
      commission = @getCommission( remote_value )
      local_value  = remote_value * @rates[@remote_currency]
      local_value += commission if @include_commission
    else
      local_value = input
      local_value = input * @rates[currency]
      commission = @getCommission( local_value )
      local_value -= commission if @include_commission
      remote_value = local_value / @rates[@remote_currency]
    # results 
    $('#amount').text( @format( local_value, @local_currency ) )
    $('#amount').attr( 'data-currency', @local_currency )
    $('#amount').attr( 'data-amount', local_value )
    $('#fees').text( @format( commission, @local_currency ) )
    $('#fees').attr( 'data-currency', @local_currency )
    $('#fees').attr( 'data-amount', commission )
    $('#total-due').text( @format( local_value + commission, @local_currency ) )
    $('#total-due').attr( 'data-currency', @local_currency )
    $('#total-due').attr( 'data-amount', local_value + commission )
    $('#recipient-receives').text( @format( remote_value ), @remote_currency )
    # currency info
    $('.local-currency').text( @local_currency )
    $('.local-currency-flag').attr 'src', "./flags/png/#{@local_currency}.png"
    $('.local-currency-symbol').text( @CURRENCY_DATA[@local_currency].symbol )
    $('.remote-currency').text( @remote_currency )
    $('.remote-currency-flag').attr 'src', "./flags/png/#{@remote_currency}.png"
    $('.remote-currency-symbol').text @CURRENCY_DATA[@remote_currency].symbol
    $('.conversion-rate').text( @format( 1 / @rates[@remote_currency], @remote_currency, 4) )
    # US rates
    $('.us-rate').each (i, ele) =>
      amount = @parseNum( $(ele).siblings('.amount').attr('data-amount') )
      currency = $(ele).siblings('.amount').data('currency')
      $(ele).find('.amount').text( @format( amount / @rates['USD'] ), 'USD' )
    if @include_us_rates
      $('.us-rate').show() 
    else
      $('.us-rate').hide() 
    # always show US rate for fees and amount to send
    $('dd.fees .us-rate, dd.amount-to-send .us-rate').show()
    if $('#input').val() == ''
      $('#result').removeClass( 'expanded' )
      $('#info').hide()
    else 
      $('#result').addClass( 'expanded' )
      $('#info').show()

  # select handler
  selectHandler:(select_id, value)->
    switch select_id
      when 'remote-country'
        $('#remote-country-flag').attr('src', "./flags/png/#{value}.png")
        span_text = @CURRENCY_DATA[value]['country']
        $('#currency select').val(value)
        @selectHandler('currency', value)
        @populateSelectOptions()
      when 'currency'
        @include_us_rates = false
        if value == 'AUD'
          @remote_currency = $('#remote-country select').val()
        else if value == 'USD' and $('#remote-country select').val() != 'USD'
          @include_us_rates = true
        else
          @remote_currency = value
        span_text = value
        @convert()
    $("##{select_id} select").siblings('span').text( span_text)
  
  # set up event listeners
  listen: ->
    @listening = true
    # select change
    $('#include-commission').on 'change', (e)=>
      @include_commission = $(e.target).is(":checked")
      @convert()
    $('.select select').on 'change', (e)=>
      @selectHandler($(e.target).parents('div').attr('id'), $(e.target).val())
      @convert()
    # input keyup
    $('#input').on 'keyup', (e)=>
      if e.target.value == ''
        delay = 0
      else
        delay = @CONFIGURATION.conversion_keypress_delay
      window.clearTimeout(window.keyboard_timeout)
      if @CONFIGURATION.continually_update_rates
        window.keyboard_timeout = window.setTimeout((=> @updateExchangeRates( => @convert() ) ), delay)
      else
        window.keyboard_timeout = window.setTimeout((=> @convert() ), delay)
    $('.select select').change()

  # format number
  format: ( number, currency='USD', significant_digits=@CONFIGURATION.significant_digits )->
    return '' if not not not number.toString().match /[0-9]/
    # not yet supported, but good idea for future implementations: return number.toLocaleString( @CURRENCY_DATA[currency].locale, { style: 'currency', currency: currency, maximumSignificantDigits: @CONFIGURATION.significant_digits } )
    number = @roundNum( number, significant_digits )
    parts = number.toString().split( '.' )
    parts[0] = parts[0].replace( /\B(?=(\d{3})+(?!\d))/g, ',' )
    parts.join '.'

  # parse number from comma delimited string 
  parseNum: ( input )->
    return '' if not input or not input.toString().replace( /,|\./g, '' ).match( /[0-9]/ )
    return parseFloat( parseFloat( input.toString().replace( /,/g, '' ) ).toFixed( @CONFIGURATION.significant_digits ) )

  # round number according to significant_digits
  roundNum:( number, significant_digits=@CONFIGURATION.significant_digits )->
    return '' if not number.toString().match /[0-9]/
    rounder = Math.pow( 10, significant_digits )
    return ( Math.round( number * rounder ) / rounder ).toFixed( significant_digits )

  # update exchange rates
  updateExchangeRates: (callback)->
    # initialize rates object 
    @rates = {} if not @rates
    # give 1 to 1 rate for local -> local currency
    @rates[@local_currency] = 1
    currencies_to_convert = []
    for currency in @CONFIGURATION.currencies_enabled_remote
      currencies_to_convert.push currency + @local_currency
    # YQL rate limit is 2,000 calls per hour per IP address - from https://developer.yahoo.com/yql/
    url = 'https://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.xchange where pair in ( "' + currencies_to_convert.join( '", "' ) + '" )&env=store://datatables.org/alltableswithkeys&format=json'
    # attempt to load exchange rates from external data
    $.get url, ( r )=>
        time = ''
        date = ''
        # update rates object 
        for rate in r.query.results.rate
          @rates[rate.id.replace( @local_currency, '' )] = rate.Rate
          date = rate.Date
          time = parseInt(rate.Time)
          time -= (new Date().getTimezoneOffset() - 5 * 60) / 60 # time zone offset
          time += 12 if rate.Time.match(/pm/i)
          time = "#{time}:#{parseInt(rate.Time.split(':')[1])}"
        d = new Date("#{date} #{time}").toLocaleString(navigator.language, {month:'2-digit', year: '2-digit', day: '2-digit', hour: '2-digit', minute:'2-digit'})
        $( '#rates-updated-at' ).html "#{d} from <a target='_blank' href='#{url}'>yahoo finance</a>"
        # perform callback if necessary
        callback() if callback

