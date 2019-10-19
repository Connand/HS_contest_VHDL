Imports System.ComponentModel
Imports System.IO
Imports System.IO.Ports
Imports System.Threading
Public Class Form1
    Dim UAR_pointer As Byte = 0
    Dim UAT_pointer As Byte = 0
    Dim UAT_data(50) As Byte
    Dim UAR_data(50) As Byte
    Dim command As Byte
    Dim sel_num As Byte
    Dim store_en As Boolean
    Dim rent_take As Boolean
    Dim storer_sel(24) As Boolean
    Dim storer_use(24) As Boolean
    Dim storers(24) As Button

    Private Sub Form1_Load(sender As Object, e As EventArgs) Handles Me.Load
        With SerialPort1
            .BaudRate = 1200 : .DataBits = 8 : .StopBits = StopBits.One : .PortName = "COM5" : .Open()
        End With
        For i = 0 To 24
            storer_sel(i) = False
            storer_use(i) = 0
        Next
        store_en = False
        sel_num = 0
        rent_take = 0 '寄物
        command = &HFF
        For i = 0 To 11
            storers(i) = Controls("Button" & (i + 3))
            storers(i).Font = New Font(storers(i).Font.FontFamily, 15, storers(i).Font.Style)
        Next
    End Sub

    Private Sub Form1_Closing(sender As Object, e As CancelEventArgs) Handles Me.Closing
        SerialPort1.Close()
    End Sub

    '委派 更新畫面
    Private Delegate Sub UpdateUICallBack(ByVal newText As String, ByVal c As Control)
    Private Sub UpdateUI(ByVal newText As String, ByVal c As Control)
        If Me.InvokeRequired() Then
            Dim cb As New UpdateUICallBack(AddressOf UpdateUI)
            Me.Invoke(cb, newText, c)
        Else
            c.Text = newText
        End If
    End Sub

    Public Function Trans_to_fpga(data() As Byte, bytes As Byte)
        For i = 0 To bytes - 1
            SerialPort1.Write(data, i, 1)
            Thread.Sleep(4) '間隔4ms避免太快接收不及
        Next
    End Function

    Private Sub Button1_Click(sender As Object, e As EventArgs) Handles Button1.Click
        '寄物
        store_en = True
        '無法選取粉色 可選取綠色 選取黃色
        rent_take = 0
        UAT_data(0) = &HCA '寄物
        Trans_to_fpga(UAT_data, 1)
    End Sub
    Private Sub Button2_Click(sender As Object, e As EventArgs) Handles Button2.Click
        '取物
        store_en = True
        '已租紅 未租綠 選取黃色
        rent_take = 1
        UAT_data(0) = &HCB '取物
        Trans_to_fpga(UAT_data, 1)
    End Sub

    Private Sub Timer1_Tick(sender As Object, e As EventArgs) Handles Timer1.Tick
        Dim buff As Byte
        Dim storer_num As Integer
        If Timer1.Interval = 1000 Then '初始到待機
            Button1.BackColor = Color.LightGray
            Button2.BackColor = Color.LightGray
            For i = 0 To 11
                storers(i).BackColor = Color.LightGray
            Next
            Timer1.Interval = 10
        End If
        If SerialPort1.BytesToRead > 0 Then
            buff = SerialPort1.ReadByte() '讀取資料--------------------------------------------
            If buff >= &HA0 Then '如果是指令
                UAR_data(0) = buff
                UAR_pointer = 1
            Else
                UAR_data(UAR_pointer) = buff
                UAR_pointer = UAR_pointer + 1
            End If
            Select Case UAR_data(0)
                Case &HEE 'EE RESET
                    Button1.BackColor = Color.LightGray
                    Button2.BackColor = Color.LightGray
                    For i = 0 To 11
                        storers(i).BackColor = Color.LightGray
                    Next
                    Button1.Enabled = True
                    Button2.Enabled = True
                    store_en = False
                    For i = 0 To 12
                        storer_sel(i) = False
                        storer_use(i) = 0
                    Next
                    sel_num = 0
                    Timer1.Interval = 1000
                Case &HAC 'AC 使用狀況 櫃子狀態 前2編號 後2狀態(X0可用X1已用1X被選)
                    If UAR_pointer > 24 Then
                        For i = 0 To 11
                            storer_num = 10 * (UAR_data(1 + 2 * i) \ 16) + (UAR_data(1 + 2 * i) Mod 16)
                            storer_use(storer_num) = UAR_data(2 * (i + 1)) Mod 16 '01XX
                            storer_sel(storer_num) = UAR_data(2 * (i + 1)) >> 4 '01XX
                            If storer_use(storer_num) = True Then '已使用的櫃子
                                If rent_take = 0 Then '寄物
                                    storers(storer_num - 1).BackColor = Color.DarkGray
                                Else '取物
                                    storers(storer_num - 1).BackColor = Color.LightGray
                                End If
                            Else
                                If rent_take = 0 Then '寄物
                                    storers(storer_num - 1).BackColor = Color.LightGray
                                Else '取物
                                    storers(storer_num - 1).BackColor = Color.DarkGray
                                End If
                            End If
                        Next
                    End If
                Case &HEA 'EA 操作結束
                    Button1.BackColor = Color.Gray
                    Button2.BackColor = Color.Gray
                    For i = 0 To 11
                        storers(i).BackColor = Color.Gray
                    Next
                    Button1.Enabled = True
                    Button2.Enabled = True
                    store_en = False
                    sel_num = 0
                    For i = 0 To 12
                        storer_sel(i) = False
                    Next
                    If UAR_data(1) = &H99 Then
                        Button1.Enabled = False
                    End If
                Case &HCA 'CA 寄物
                    Button1.BackColor = Color.GreenYellow
                    Button2.BackColor = Color.White
                    Button2.Enabled = False

                Case &HCB 'CB取物
            End Select
        End If

    End Sub

    Private Sub Button3_Click(sender As Object, e As EventArgs) Handles Button3.Click, Button4.Click, Button5.Click, Button6.Click, Button7.Click, Button8.Click, Button9.Click, Button10.Click, Button11.Click, Button12.Click, Button13.Click, Button14.Click
        If store_en Then
            Dim sel As Byte = ((Int(Mid(sender.Text, 1, 1)) - 1) * 4 + Int(Mid(sender.Text, 3, 1)))
            storer_sel(sel) = Not storer_sel(sel)
            If storer_sel(sel) Then
                If rent_take = 0 Then
                    If sel_num > 7 Then
                        storer_sel(sel) = Not storer_sel(sel)
                    Else
                        sel_num = sel_num + 1
                    End If
                Else
                    If sel_num > 0 Then
                        storer_sel(sel) = Not storer_sel(sel)
                    Else
                        sel_num = sel_num + 1
                    End If
                End If
            Else
                sel_num = sel_num - 1
            End If
            If rent_take = 0 Then '寄物
                If storer_use(sel) Then '已使用的櫃子
                    sender.BackColor = Color.DarkGray
                Else
                    If storer_sel(sel) Then
                        sender.BackColor = Color.GreenYellow
                    Else
                        sender.BackColor = Color.LightGray
                    End If
                End If
            Else '取物
                If storer_use(sel) = False Then '沒有 使用的櫃子
                    sender.BackColor = Color.GreenYellow
                Else
                    If storer_sel(sel) Then
                        sender.BackColor = Color.GreenYellow
                    Else
                        sender.BackColor = Color.LightGray
                    End If
                End If
            End If

            UAT_data(0) = &HAB '選取情形
            UAT_data(1) = ((sel \ 10) << 4) + (sel Mod 10)
            If storer_sel(sel) Then
                UAT_data(2) = &H10 '選擇
            Else
                UAT_data(2) = &H0 '沒選
            End If
            Trans_to_fpga(UAT_data, 3)
        End If
    End Sub


End Class
