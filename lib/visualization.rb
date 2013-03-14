class Visualization
  def initialize(data, params)
    @data = data
    @start_date = params[:start_date] || Date.today
    @end_date = params[:end_date] || Date.today + 365
  end

  def data_array
    months = []
    (@start_date.year..@end_date.year).each do |y|
       mo_start = (@start_date.year == y) ? @start_date.month : 1
       mo_end = (@end_date.year == y) ? @end_date.month : 12

       (mo_start..mo_end).each do |m|  
           months << "#{m}/#{y}"
       end
    end

    array = []

    header_array = ["Month"]
    @data.each do |datum|
      header_array.push datum.name
    end

    array.push(header_array)

    months.each do |date|
      date_date = Date.parse(date)
      row = [date]
      @data.each do |datum|
        date_range = (Date.parse(datum.expected_start_date.to_s)..Date.parse(datum.expected_end_date.to_s))
        if date_range.include?(date_date)
          row.push(datum.price)
        else
          row.push(0)
        end
      end
      array.push(row)
    end
    array
  end
end