class Converter

  CONFIGURATION:
    # conversion keypress delay - time in milliseconds to wait after keypress before converting
    conversion_keypress_delay: 500
    # number of decimal places to calculate conversions to
    significant_digits: 2
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
    # get default remote currency
    @remote_currency = @CONFIGURATION.currencies_enabled_remote[0]
    # get default local currency
    @local_currency = @CONFIGURATION.currencies_enabled_local[0]
    # update exchange rates from external source
    @updateExchangeRates( => @convert() )
    # create dropdowns
    @createInputs()
    # listen for input changes
    @listen()

  # create inputs
  createInputs: ->
    # populate country options once only
    if $('#remote-country select').text() == ''
      for currency in @CONFIGURATION.currencies_enabled_remote
        currency_data = @CURRENCY_DATA[currency]
        $('#remote-country select').append( "<option value='#{currency}'>#{currency_data.country}</option>" )
    # populate currency select each time function is called
    $('#send-receive-currency select').html('')
    if $('#send-receive-toggle select').val() == 'send'
      $('#send-receive-currency select').append( "<option value='#{@local_currency}'>#{@local_currency}</option>" )
      #$('#send-receive-currency select').append( "<option value='#{@remote_currency}'>#{@remote_currency}</option>" )
    else
      $('#send-receive-currency select').append( "<option value='#{@remote_currency}'>#{@remote_currency}</option>" )
      #$('#send-receive-currency select').append( "<option value='#{@local_currency}'>#{@local_currency}</option>" )
    # trigger on change event for currency select
    $('#send-receive-currency select').change()

  # log
  log: (input, style)->
    console.log("%c #{input}", style) if window.enable_log

  # return comission rate for given value
  getCommission: ( amount )->
    amount = @parseNum( amount )
    @commission_rate = 0.05
    @commission_rate = 0.04 if amount > 1000
    @commission_rate = 0.03 if amount > 3000
    @commission_rate = 0.02 if amount > 4000
    @commission_rate = 0.02 if amount > 5000 # negotiable
    return amount * @commission_rate

  # convert
  convert: ->
    rate = @rates[@remote_currency]
    if $('#send-receive-toggle select').val() == 'send'
      local_value = @parseNum( $('#send-receive-amount').val() )
      remote_value = local_value / rate
    else
      remote_value = @parseNum( $('#send-receive-amount').val() )
      local_value = remote_value * rate
    commission = @getCommission( local_value )
    # results 
    $('#amount').text( @format( local_value, @local_currency ) )
    $('#fees').text( @format( commission, @local_currency ) )
    $('#total-due').text( @format( local_value + commission, @local_currency ) )
    $('#recipient-receives').text( @format( remote_value ), @remote_currency )
    # currency info
    $('.local-currency').text( @local_currency )
    $('.local-currency-flag').attr 'src', "./flags/png/#{@local_currency}.png"
    $('.local-currency-symbol').text( @CURRENCY_DATA[@local_currency].symbol )
    $('.remote-currency').text( @remote_currency )
    $('.remote-currency-flag').attr 'src', "./flags/png/#{@remote_currency}.png"
    $('.remote-currency-symbol').text @CURRENCY_DATA[@remote_currency].symbol
    $('.conversion-rate').text( @format( 1 / @rates[@remote_currency], @remote_currency, 4) )
    if local_value.toString() == ''
      $('#result').removeClass( 'expanded' )
      $('#info').hide()
    else if remote_value.toString() != ''
      $('#result').addClass( 'expanded' )
      $('#info').show()

  # select handler
  selectHandler:(select_id, value)->
    switch select_id
      when 'send-receive-toggle'
        span_text = value[0].toUpperCase() + value.slice(1)
        @createInputs()
      when 'remote-country'
        $('#remote-country-flag').attr('src', "./flags/png/#{value}.png")
        span_text = @CURRENCY_DATA[value]['country']
        $('#send-receive-currency select').val(value)
        @selectHandler('send-receive-currency', value)
        @createInputs()
      when 'send-receive-currency'
        if value == 'AUD'
          @remote_currency = $('#remote-country select').val()
        else
          @remote_currency = value
        span_text = value
    $("##{select_id} select").siblings('span').text( span_text)
  
  # set up event listeners
  listen: ->
    @listening = true
    # select change
    $('.select select').on 'change', (e)=>
      @selectHandler($(e.target).parents('div').attr('id'), $(e.target).val())
      @convert()
    # input keyup
    $('#send-receive-amount').on 'keyup', (e)=>
      if e.target.value == ''
        delay = 0
      else
        delay = @CONFIGURATION.conversion_keypress_delay
      window.clearTimeout(window.keyboard_timeout)
      window.keyboard_timeout = window.setTimeout((=> @convert()), delay)
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
    return '' if not input.toString().replace( /,|\./g, '' ).match( /[0-9]/ )
    return parseFloat( parseFloat( input.toString().replace( /\,/g, '' ) ).toFixed( @CONFIGURATION.significant_digits ) )

  # round number according to significant_digits
  roundNum:( number, significant_digits=@CONFIGURATION.significant_digits )->
    return '' if not number.toString().match /[0-9]/
    rounder = Math.pow( 10, significant_digits )
    return ( Math.round( number * rounder ) / rounder ).toFixed( significant_digits )

  # update exchange rates
  updateExchangeRates: (callback)->
    # initialize rates object 
    @rates = {} if not @rates
    @rates[@local_currency] = 1
    # if manual input has been specified dont update
    return false if @manual_input != undefined
    currencies_to_convert = []
    for currency in @CONFIGURATION.currencies_enabled_remote
      currencies_to_convert.push currency + @local_currency
    # YQL rate limit is 2,000 calls per hour per IP address - from https://developer.yahoo.com/yql/
    url = 'https://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.xchange where pair in ( "' + currencies_to_convert.join( '", "' ) + '" )&env=store://datatables.org/alltableswithkeys&format=json'
    # attempt to load exchange rates from external data
    $.get url, ( r )=>
        # update rates object 
        for rate in r.query.results.rate
          @rates[rate.id.replace( @local_currency, '' )] = rate.Rate
          $( '#rates-updated-at' ).html "#{rate.Date} #{rate.Time} from <a target='_blank' href='#{url}'>yahoo finance data</a>"
        callback() if callback

