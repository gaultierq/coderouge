require "application_system_test_case"

class WaypointsTest < ApplicationSystemTestCase
  setup do
    @waypoint = waypoints(:one)
  end

  test "visiting the index" do
    visit waypoints_url
    assert_selector "h1", text: "Waypoints"
  end

  test "creating a Waypoint" do
    visit waypoints_url
    click_on "New Waypoint"

    fill_in "Date", with: @waypoint.date
    fill_in "Latitude", with: @waypoint.latitude
    fill_in "Logbook", with: @waypoint.logbook
    fill_in "Longitude", with: @waypoint.longitude
    click_on "Create Waypoint"

    assert_text "Waypoint was successfully created"
    click_on "Back"
  end

  test "updating a Waypoint" do
    visit waypoints_url
    click_on "Edit", match: :first

    fill_in "Date", with: @waypoint.date
    fill_in "Latitude", with: @waypoint.latitude
    fill_in "Logbook", with: @waypoint.logbook
    fill_in "Longitude", with: @waypoint.longitude
    click_on "Update Waypoint"

    assert_text "Waypoint was successfully updated"
    click_on "Back"
  end

  test "destroying a Waypoint" do
    visit waypoints_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Waypoint was successfully destroyed"
  end
end
