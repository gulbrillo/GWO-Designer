print DET <<EOF;
{
        "detectorName": {
                "name": "$in{name}"
        },
        "waistPosition": {
                "position": "$wherewaist",
                "textElement": "ist da so ungefähr"
        },
        "waistTransitter": {
                "value": "$printgaussianradius",
                "unit": "cm"
        },
        "waistCenter": {
                "value": "$Wocenter",
                "unit": "m"
        },
        "beamIntensity": {
                "value": "$printintensity",
                "unit": "$printintensityu/m²"
        },
        "beamDiameterTransmitterWaist": {
                "value": "$printspotsizeatrec",
                "unit": "$printspotsizeatrecu"
        },
        "beamDiameterCenterWaist": {
                "value": "$spotsizeatreccenter",
                "unit": "m"
        },
        "receivedPower": {
                "value": "$printreceived",
                "unit": "$printreceivedu"
        }
}
EOF

