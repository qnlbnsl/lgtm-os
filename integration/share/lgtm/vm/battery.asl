/*
 * Fake battery for VMs with a laptop NVIDIA GPU passed through. NVIDIA's laptop driver
 * expects to run on a battery-powered machine and may refuse to start (Code 43)
 * without one. lgtm-vm compiles this with iasl and adds it as an ACPI table.
 */
DefinitionBlock ("", "SSDT", 1, "LGTM", "BATTERY", 0x00000001)
{
    External (_SB_, DeviceObj)
    Scope (\_SB)
    {
        Device (BAT0)
        {
            Name (_HID, EisaId ("PNP0C0A"))
            Name (_UID, One)
            Method (_STA, 0, NotSerialized) { Return (0x1F) }
            Method (_BIF, 0, NotSerialized)
            {
                Return (Package (0x0D)
                {
                    One, 0x1770, 0x1770, One, 0x39D0, 0x0258, 0x012C,
                    0x3C, 0x3C, "LGTM", "1", "LION", "LGTM OS"
                })
            }
            Method (_BST, 0, NotSerialized)
            {
                Return (Package (0x04) { Zero, Zero, 0x1770, 0x39D0 })
            }
        }
    }
}
