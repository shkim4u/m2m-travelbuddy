import React, {Component, useEffect, useState} from "react";
import {useDispatch, useSelector} from "react-redux";
import {hotelSpecialsAction, hotelSpecialsSelector} from "../../../features/hotelspecials/slice";
import Loader from "../../loader";
import Error from "../../error";
import moment from "moment";
import {flightSpecialsAction, flightSpecialsSelector} from "../../../features/flightspecials/slice";

const SpecialsData = () => {
    // render() {
        const dispatch = useDispatch();
        // FlightSpecials.
        const [flightSpecialsState, setFlightSpecialsState] = useState({
            isLoading: false,
            flightSpecials: [],
            error: null,
            page: 0
        });
        const {
            isLoading: isFlightSpecialsLoading,
            flightSpecials,
            error: flightSpecialsError
        } = useSelector(flightSpecialsSelector.all);

        // HotelSpecials.
        const [hotelSpecialsState, setHotelSpecialsState] = useState({
            isLoading: false,
            hotelSpecials: [],
            error: null,
            page: 0
        });
        const {
            isLoading: isHotelSpecialsLoading,
            hotelSpecials,
            error: hotelSpecialsError
        } = useSelector(hotelSpecialsSelector.all);

        // useInfiniteScroll({
        //     target,
        //     onIntersect: ([{isIntersecting}]) => {
        //         if (isIntersecting) {
        //             dispatch(hotelSpecialsAction.loadMore());
        //         }
        //     }
        // });

        useEffect(() => {
           dispatch(flightSpecialsAction.load())
        }, []);
        useEffect(() => {
            dispatch(hotelSpecialsAction.load());
        }, []);

        if (isFlightSpecialsLoading || isHotelSpecialsLoading) {
            return <Loader />;
        }

        if (flightSpecialsError || hotelSpecialsError) {
            return <Error />;
        }

        console.log("SpecialsData render().");
        console.log(`flightSpecials: ${flightSpecials}`);
        console.log(`hotelSpecials: ${hotelSpecials}`);
        return (
            <>
                {/*TravelBuddy Specials (Hotels & Flight) Data*/}
                <div className="container marketing">
                    <div className="row block flightdestinationblock">
                        <div className="col-md-6">
                            <h2>Today's flight specials</h2>
                            {
                                flightSpecials?.map((flightSpecial) => (
                                    <div className="flightspecialbox">
                                        <table>
                                            <tbody>
                                            <tr>
                                                <td className="flighticon-urgent" width="40">
                                                        <span className="glyphicon glyphicon-send flighticon flighticon-urgent" aria-hidden={true}>
                                                        </span>
                                                </td>
                                                <td className="flightdestination" width="400">
                                                    {flightSpecial.header}<br></br>
                                                    <span className="flightdescription">
                                                        {flightSpecial.body}
                                                    </span>
                                                </td>
                                                <td className="flightprice">
                                                    ${flightSpecial.cost}
                                                </td>
                                                <td width="200">
                                                    <span className="flighttime pull-right">
                                                        {moment(flightSpecial.expiryDate).format('YYYY-MM-DD HH:mm:ss')}
                                                    </span>
                                                </td>
                                            </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                ))
                            }
                        </div>

                        <div className="col-md-6">
                            <h2>Today's hotel specials</h2>
                            {
                                hotelSpecials?.map((hotelSpecial) => (
                                    <div className="flightspecialbox">
                                        <table>
                                            <tbody>
                                                <tr>
                                                    <td className="flighticon" width="40">
                                                        <span className="glyphicon glyphicon-send flighticon" aria-hidden={true}>
                                                        </span>
                                                    </td>
                                                    <td className="flightdestination" width="400">
                                                        {hotelSpecial.hotel} - {hotelSpecial.location}<br></br>
                                                        <span className="flightdescription">
                                                            {hotelSpecial.description}
                                                        </span>
                                                    </td>
                                                    <td className="flightprice">
                                                        ${hotelSpecial.cost}
                                                    </td>
                                                    <td width="200">
                                                        <span className="flighttime pull-right">
                                                            {moment(hotelSpecial.expiryDate).format('YYYY-MM-DD HH:mm:ss')}
                                                        </span>
                                                    </td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                ))
                            }
                        </div>
                    </div>
                </div>
            </>
        );
    // }
}

export default SpecialsData;
