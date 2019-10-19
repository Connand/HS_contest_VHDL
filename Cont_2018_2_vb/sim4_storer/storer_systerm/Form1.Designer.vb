<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class Form1
    Inherits System.Windows.Forms.Form

    'Form 覆寫 Dispose 以清除元件清單。
    <System.Diagnostics.DebuggerNonUserCode()>
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    '為 Windows Form 設計工具的必要項
    Private components As System.ComponentModel.IContainer

    '注意: 以下為 Windows Form 設計工具所需的程序
    '可以使用 Windows Form 設計工具進行修改。
    '請勿使用程式碼編輯器進行修改。
    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        Me.components = New System.ComponentModel.Container()
        Me.Button1 = New System.Windows.Forms.Button()
        Me.Button2 = New System.Windows.Forms.Button()
        Me.Button3 = New System.Windows.Forms.Button()
        Me.SerialPort1 = New System.IO.Ports.SerialPort(Me.components)
        Me.Timer1 = New System.Windows.Forms.Timer(Me.components)
        Me.Button4 = New System.Windows.Forms.Button()
        Me.Button5 = New System.Windows.Forms.Button()
        Me.Button6 = New System.Windows.Forms.Button()
        Me.Button7 = New System.Windows.Forms.Button()
        Me.Button8 = New System.Windows.Forms.Button()
        Me.Button9 = New System.Windows.Forms.Button()
        Me.Button10 = New System.Windows.Forms.Button()
        Me.Button11 = New System.Windows.Forms.Button()
        Me.Button12 = New System.Windows.Forms.Button()
        Me.Button13 = New System.Windows.Forms.Button()
        Me.Button14 = New System.Windows.Forms.Button()
        Me.SuspendLayout()
        '
        'Button1
        '
        Me.Button1.Font = New System.Drawing.Font("標楷體", 13.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(136, Byte))
        Me.Button1.Location = New System.Drawing.Point(43, 38)
        Me.Button1.Name = "Button1"
        Me.Button1.Size = New System.Drawing.Size(137, 81)
        Me.Button1.TabIndex = 0
        Me.Button1.Text = "寄放行李"
        Me.Button1.UseVisualStyleBackColor = True
        '
        'Button2
        '
        Me.Button2.Font = New System.Drawing.Font("標楷體", 13.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(136, Byte))
        Me.Button2.Location = New System.Drawing.Point(43, 125)
        Me.Button2.Name = "Button2"
        Me.Button2.Size = New System.Drawing.Size(137, 81)
        Me.Button2.TabIndex = 1
        Me.Button2.Text = "取出行李"
        Me.Button2.UseVisualStyleBackColor = True
        '
        'Button3
        '
        Me.Button3.Font = New System.Drawing.Font("標楷體", 13.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(136, Byte))
        Me.Button3.Location = New System.Drawing.Point(262, 38)
        Me.Button3.Name = "Button3"
        Me.Button3.Size = New System.Drawing.Size(90, 81)
        Me.Button3.TabIndex = 2
        Me.Button3.Text = "1-1"
        Me.Button3.UseVisualStyleBackColor = True
        '
        'SerialPort1
        '
        Me.SerialPort1.BaudRate = 1200
        Me.SerialPort1.PortName = "COM5"
        '
        'Timer1
        '
        Me.Timer1.Enabled = True
        Me.Timer1.Interval = 50
        '
        'Button4
        '
        Me.Button4.Font = New System.Drawing.Font("標楷體", 13.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(136, Byte))
        Me.Button4.Location = New System.Drawing.Point(358, 38)
        Me.Button4.Name = "Button4"
        Me.Button4.Size = New System.Drawing.Size(90, 81)
        Me.Button4.TabIndex = 3
        Me.Button4.Text = "1-2"
        Me.Button4.UseVisualStyleBackColor = True
        '
        'Button5
        '
        Me.Button5.Font = New System.Drawing.Font("標楷體", 13.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(136, Byte))
        Me.Button5.Location = New System.Drawing.Point(454, 38)
        Me.Button5.Name = "Button5"
        Me.Button5.Size = New System.Drawing.Size(90, 81)
        Me.Button5.TabIndex = 4
        Me.Button5.Text = "1-3"
        Me.Button5.UseVisualStyleBackColor = True
        '
        'Button6
        '
        Me.Button6.Font = New System.Drawing.Font("標楷體", 13.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(136, Byte))
        Me.Button6.Location = New System.Drawing.Point(550, 38)
        Me.Button6.Name = "Button6"
        Me.Button6.Size = New System.Drawing.Size(90, 81)
        Me.Button6.TabIndex = 5
        Me.Button6.Text = "1-4"
        Me.Button6.UseVisualStyleBackColor = True
        '
        'Button7
        '
        Me.Button7.Font = New System.Drawing.Font("標楷體", 13.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(136, Byte))
        Me.Button7.Location = New System.Drawing.Point(262, 125)
        Me.Button7.Name = "Button7"
        Me.Button7.Size = New System.Drawing.Size(90, 109)
        Me.Button7.TabIndex = 6
        Me.Button7.Text = "2-1"
        Me.Button7.UseVisualStyleBackColor = True
        '
        'Button8
        '
        Me.Button8.Font = New System.Drawing.Font("標楷體", 13.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(136, Byte))
        Me.Button8.Location = New System.Drawing.Point(358, 125)
        Me.Button8.Name = "Button8"
        Me.Button8.Size = New System.Drawing.Size(90, 109)
        Me.Button8.TabIndex = 7
        Me.Button8.Text = "2-2"
        Me.Button8.UseVisualStyleBackColor = True
        '
        'Button9
        '
        Me.Button9.Font = New System.Drawing.Font("標楷體", 13.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(136, Byte))
        Me.Button9.Location = New System.Drawing.Point(454, 125)
        Me.Button9.Name = "Button9"
        Me.Button9.Size = New System.Drawing.Size(90, 109)
        Me.Button9.TabIndex = 8
        Me.Button9.Text = "2-3"
        Me.Button9.UseVisualStyleBackColor = True
        '
        'Button10
        '
        Me.Button10.Font = New System.Drawing.Font("標楷體", 13.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(136, Byte))
        Me.Button10.Location = New System.Drawing.Point(550, 125)
        Me.Button10.Name = "Button10"
        Me.Button10.Size = New System.Drawing.Size(90, 109)
        Me.Button10.TabIndex = 9
        Me.Button10.Text = "2-4"
        Me.Button10.UseVisualStyleBackColor = True
        '
        'Button11
        '
        Me.Button11.Font = New System.Drawing.Font("標楷體", 13.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(136, Byte))
        Me.Button11.Location = New System.Drawing.Point(262, 240)
        Me.Button11.Name = "Button11"
        Me.Button11.Size = New System.Drawing.Size(90, 149)
        Me.Button11.TabIndex = 10
        Me.Button11.Text = "3-1"
        Me.Button11.UseVisualStyleBackColor = True
        '
        'Button12
        '
        Me.Button12.Font = New System.Drawing.Font("標楷體", 13.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(136, Byte))
        Me.Button12.Location = New System.Drawing.Point(358, 240)
        Me.Button12.Name = "Button12"
        Me.Button12.Size = New System.Drawing.Size(90, 149)
        Me.Button12.TabIndex = 11
        Me.Button12.Text = "3-2"
        Me.Button12.UseVisualStyleBackColor = True
        '
        'Button13
        '
        Me.Button13.Font = New System.Drawing.Font("標楷體", 13.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(136, Byte))
        Me.Button13.Location = New System.Drawing.Point(454, 240)
        Me.Button13.Name = "Button13"
        Me.Button13.Size = New System.Drawing.Size(90, 149)
        Me.Button13.TabIndex = 12
        Me.Button13.Text = "3-3"
        Me.Button13.UseVisualStyleBackColor = True
        '
        'Button14
        '
        Me.Button14.Font = New System.Drawing.Font("標楷體", 13.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(136, Byte))
        Me.Button14.Location = New System.Drawing.Point(550, 240)
        Me.Button14.Name = "Button14"
        Me.Button14.Size = New System.Drawing.Size(90, 149)
        Me.Button14.TabIndex = 13
        Me.Button14.Text = "3-4"
        Me.Button14.UseVisualStyleBackColor = True
        '
        'Form1
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(8.0!, 15.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(800, 450)
        Me.Controls.Add(Me.Button14)
        Me.Controls.Add(Me.Button13)
        Me.Controls.Add(Me.Button12)
        Me.Controls.Add(Me.Button11)
        Me.Controls.Add(Me.Button10)
        Me.Controls.Add(Me.Button9)
        Me.Controls.Add(Me.Button8)
        Me.Controls.Add(Me.Button7)
        Me.Controls.Add(Me.Button6)
        Me.Controls.Add(Me.Button5)
        Me.Controls.Add(Me.Button4)
        Me.Controls.Add(Me.Button3)
        Me.Controls.Add(Me.Button2)
        Me.Controls.Add(Me.Button1)
        Me.Name = "Form1"
        Me.Text = "寄物櫃管理系統"
        Me.ResumeLayout(False)

    End Sub

    Friend WithEvents Button1 As Button
    Friend WithEvents Button2 As Button
    Friend WithEvents Button3 As Button
    Friend WithEvents SerialPort1 As IO.Ports.SerialPort
    Friend WithEvents Timer1 As Timer
    Friend WithEvents Button4 As Button
    Friend WithEvents Button5 As Button
    Friend WithEvents Button6 As Button
    Friend WithEvents Button7 As Button
    Friend WithEvents Button8 As Button
    Friend WithEvents Button9 As Button
    Friend WithEvents Button10 As Button
    Friend WithEvents Button11 As Button
    Friend WithEvents Button12 As Button
    Friend WithEvents Button13 As Button
    Friend WithEvents Button14 As Button
End Class
