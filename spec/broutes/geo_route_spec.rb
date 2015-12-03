require 'spec_helper'
require 'pry'

describe GeoRoute do
  describe "#add_point" do
    before(:each) do
      @route = GeoRoute.new
      @lat = random_lat
      @lon = random_lon
      @elevation = 35.6000000
      @new_point = GeoPoint.new(lat: @lat, lon: @lon, elevation: @elevation, distance: 0)
    end

    subject { @route.add_point(lat: @lat, lon: @lon, elevation: @elevation) }

    context "when route is empty" do

      it "sets the start point to the new_point" do
        subject
        @route.start_point.should eq(@new_point)
      end
      it "should set the total distance to zero" do
        subject
        @route.total_distance.should eq(0)
      end
      it "should add the start point to the points list" do
        subject
        @route.points.first.should eq(@route.start_point)
      end
    end
    context "when route already has a start point" do
      before(:each) do
        @start_point = GeoPoint.new(lat: random_lat, lon: random_lon, elevation: random_elevation, distance: 0)
        @route.add_point(lat: @start_point.lat, lon: @start_point.lon, elevation: @start_point.elevation)
      end

      it "should not change start_point" do
        subject
        @route.start_point.should eq(@start_point)
      end
      it "should set the total distance to be haversine distance between the start_point and the new point" do
        subject
        @route.total_distance.should eq(Maths.haversine_distance(@start_point, @new_point).round)
      end
      it "set the distance of the point to be the haverside_distance between the start_point" do
        subject
        last(@route.points).distance.should eq(Maths.haversine_distance(@start_point, @new_point))
      end
    end

    context "when route already has at least two points" do
      before(:each) do
        @start_point = GeoPoint.new(lat: random_lat, lon: random_lon, elevation: random_elevation)
        @next_point = GeoPoint.new(lat: random_lat, lon: random_lon, elevation: random_elevation)
        @route.add_point(lat: @start_point.lat, lon: @start_point.lon, elevation: @start_point.elevation)
        @route.add_point(lat: @next_point.lat, lon: @next_point.lon, elevation: @next_point.elevation)
      end
      it "should set the total distance to haversine distance along all points" do
        subject
        @route.total_distance.should be_within(1).of(
          Maths.haversine_distance(@start_point, @next_point).round +
          Maths.haversine_distance(@next_point, @new_point).round
          )
      end
      it "set the distance of the point to haversine distance along all points" do
        subject
        last(@route.points).distance.should eq(
          Maths.haversine_distance(@start_point, @next_point) +
          Maths.haversine_distance(@next_point, @new_point)
          )
      end
    end
  end
  describe "#process_elevation_delta" do
    before(:each) do
      @route = GeoRoute.new
      @next_point = GeoPoint.new(lat: random_lat, lon: random_lon, elevation: random_elevation)
    end

    subject { @route.process_elevation_delta(@last_point, @next_point) }

    context "when last_point is nil" do
      it "has an total_ascent of nil" do
        subject
        @route.total_ascent.should eq(0)
      end
      it "has an total_descent of nil" do
        subject
        @route.total_descent.should eq(0)
      end
    end
    context "when last_point is same elevation as next point" do
      before(:each) do
        @last_point = GeoPoint.new(lat: random_lat, lon: random_lon, elevation: @next_point.elevation)
      end
      it "has an total_ascent of zero" do
        subject
        @route.total_ascent.should eq(0)
      end
      it "has an total_descent of zero" do
        subject
        @route.total_descent.should eq(0)
      end
    end
    context "when last_point is lower than the next point" do
      before(:each) do
        @delta = random_elevation
        @last_point = GeoPoint.new(lat: random_lat, lon: random_lon, elevation: @next_point.elevation - @delta)
      end
      it "the delta is added to the total_ascent" do
        subject
        round_to(@route.total_ascent, 3).should eq(@delta)
      end
      it "has an total_descent of zero" do
        subject
        @route.total_descent.should eq(0)
      end
    end
    context "when last_point is higher than the next point" do
      before(:each) do
        @delta = random_elevation
        @last_point = GeoPoint.new(lat: random_lat, lon: random_lon, elevation: @next_point.elevation + @delta)
      end
      it "has an total_ascent of zero" do
        subject
        @route.total_ascent.should eq(0)
      end
      it "the delta is added to the total_descent" do
        subject
        round_to(@route.total_descent, 3).should eq(@delta)
      end
    end
  end
  describe "#hilliness" do
    before(:each) do
      @route = GeoRoute.new
    end

    subject { @route.hilliness }

    context "when 1000 m ascent in 100km" do
      before(:each) do
        @route.stub(:total_distance) { 100000 }
        @route.stub(:total_ascent) { 1000 }
      end
      it "is 10" do
        subject.should eq(10)
      end
    end
    context "when 0 ascent in 100km" do
      before(:each) do
        @route.stub(:total_distance) { 100000 }
        @route.stub(:total_ascent) { 0 }
      end
      it "is 0" do
        subject.should eq(0)
      end
    end
    context "when 1000 ascent in 0km" do
      before(:each) do
        @route.stub(:total_distance) { 0 }
        @route.stub(:total_ascent) { 1000 }
      end
      it "is 0" do
        subject.should eq(0)
      end
    end
  end

  describe "#average_heart_rate" do
    before(:each) do
      @route = GeoRoute.new
    end

    context 'when the route points have heart rates' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation, heart_rate: 15)
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation, heart_rate: 10)
      end
      it 'should return average heart rate' do
        @route.average_heart_rate.should eq(12)
      end
    end
    context 'when the route points have no heart rate' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation)
      end
      it 'should return 0' do
        @route.average_heart_rate.should eq(0)
      end
    end
  end

  describe "#maximum_heart_rate" do
    before(:each) do
      @route = GeoRoute.new
    end

    context 'when the route points have heart rates' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation, heart_rate: 15)
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation, heart_rate: 10)
      end
      it 'should return maximum heart rate' do
        @route.maximum_heart_rate.should eq(15)
      end
    end
    context 'when the route points have no heart rate' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation)
      end
      it 'should return 0' do
        @route.maximum_heart_rate.should eq(0)
      end
    end
  end

  describe "#minimum_heart_rate" do
    before(:each) do
      @route = GeoRoute.new
    end

    context 'when the route points have heart rates' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation, heart_rate: 15)
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation, heart_rate: 10)
      end
      it 'should return minimum heart rate' do
        @route.minimum_heart_rate.should eq(10)
      end
    end
    context 'when the route points have no heart rate' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation)
      end
      it 'should return 0' do
        @route.minimum_heart_rate.should eq(0)
      end
    end
  end

  describe "#maximum_elevation" do
    before(:each) do
      @route = GeoRoute.new
    end

    context 'when the route points have elevations' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, elevation: 217)
        @route.add_point(lat: random_lat, lon: random_lon, elevation: 212)
      end
      it 'should return maximum elevation' do
        @route.maximum_elevation.should eq(217)
      end
    end
    context 'when the route points have no elevations' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon)
      end
      it 'should return 0' do
        @route.maximum_elevation.should eq(0)
      end
    end
  end

  describe "#minimum_elevation" do
    before(:each) do
      @route = GeoRoute.new
    end

    context 'when the route points have elevations' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, elevation: 217)
        @route.add_point(lat: random_lat, lon: random_lon, elevation: 212)
      end
      it 'should return minimum elevation' do
        @route.minimum_elevation.should eq(212)
      end
    end
    context 'when the route points have no elevations' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon)
      end
      it 'should return 0' do
        @route.maximum_elevation.should eq(0)
      end
    end
  end

  describe "#average_power" do
    before(:each) do
      @route = GeoRoute.new
    end

    context 'when the route points have power' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation, power: 250)
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation, power: 233)
      end
      it 'should return average power' do
        @route.average_power.should eq(241)
      end
    end
    context 'when the route points have no power' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation)
      end
      it 'should return 0' do
        @route.average_power.should eq(0)
      end
    end
  end

  describe "#maximum_speed" do
    before(:each) do
      @route = GeoRoute.new
    end

    context 'when the route points have speed' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation, speed: 4.00)
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation, speed: 2.00)
      end
      it 'should return maximum speed' do
        @route.maximum_speed.should eq(4.00)
      end
    end
    context 'when the route points have no speed' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation)
      end
      it 'should return 0' do
        @route.maximum_speed.should eq(0.0)
      end
    end
  end

  describe "#minimum_speed" do
    before(:each) do
      @route = GeoRoute.new
    end

    context 'when the route points have speed' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation, speed: 4.00)
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation, speed: 2.00)
      end
      it 'should return minimum speed' do
        @route.minimum_speed.should eq(2.00)
      end
    end
    context 'when the route points have no speed' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation)
      end
      it 'should return 0' do
        @route.minimum_speed.should eq(0.0)
      end
    end
  end

  describe "#average_speed" do
    before(:each) do
      @route = GeoRoute.new
    end

    context 'when the route points have speed' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation, speed: 4.00)
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation, speed: 2.00)
      end
      it 'should return average speed' do
        @route.average_speed.should eq(3.00)
      end
    end
    context 'when the route points have no speed' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, elevation: random_elevation)
      end
      it 'should return 0' do
        @route.average_speed.should eq(0)
      end
    end
  end

  describe "#total_calories" do
    before(:each) do
      @route = GeoRoute.new
    end

    context 'when route laps have calories' do
      before(:each) do
        @route.add_lap(calories: 12)
      end
      it 'should return the calories' do
        @route.total_calories.should eq(12)
      end
    end
    context 'when route laps do not have calories' do
      before(:each) do
        @route.add_lap(distance: random_integer)
      end
      it 'should return 0' do
        @route.total_calories.should eq(0)
      end
    end
    context 'when route does not have laps' do
      it 'should return 0' do
        @route.total_calories.should eq(0)
      end
    end
  end

  describe '#average_cadence' do
    before(:each) do
      @route = GeoRoute.new
    end
    context 'when route points have cadence' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, cadence: 74)
        @route.add_point(lat: random_lat, lon: random_lon, cadence: 80)
      end
      it 'should return the average cadence' do
        @route.average_cadence.should eq(77)
      end
    end
    context 'when route points do not have cadence' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon)
        @route.add_point(lat: random_lat, lon: random_lon)
      end
      it 'should return 0' do
        @route.average_cadence.should eq(0)
      end
    end
  end

  describe '#maximum_cadence' do
    before(:each) do
      @route = GeoRoute.new
    end
    context 'when route points have cadence' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon, cadence: 74)
        @route.add_point(lat: random_lat, lon: random_lon, cadence: 80)
      end
      it 'should return the maximum cadence' do
        @route.maximum_cadence.should eq(80)
      end
    end
    context 'when route points do not have cadence' do
      before(:each) do
        @route.add_point(lat: random_lat, lon: random_lon)
        @route.add_point(lat: random_lat, lon: random_lon)
      end
      it 'should return 0' do
        @route.maximum_cadence.should eq(0)
      end
    end
  end

  describe ".from_hash" do
    let(:started_at) { Time.now }
    let(:points) {[
      GeoPoint.new(lat: random_lat, lon: random_lon, time: started_at),
      GeoPoint.new(lat: random_lat, lon: random_lon, time: started_at + 1),
      GeoPoint.new(lat: random_lat, lon: random_lon, time: started_at + 2),
      ]}
    let(:laps) {[
      Lap.new(start_time: started_at, distance: random_integer, time: random_integer),
      Lap.new(start_time: started_at + 1, distance: random_integer, time: random_integer),
      Lap.new(start_time: started_at + 2, distance: random_integer, time: random_integer)
      ]}
    let(:hash) {{
      'started_at' => started_at,
      'points' => points.collect { |p| p.to_hash },
      'laps' => laps.collect { |l| l.to_hash }
    }}

    subject { GeoRoute.from_hash hash }

    it "set the started_at" do
      subject.started_at.to_i.should eq(started_at.to_i)
    end
    it "has the requisite number of points" do
      subject.points.count.should eq(points.count)
    end
    it "has the requisite number of laps" do
      subject.laps.count.should eq(laps.count)
    end
  end
end
