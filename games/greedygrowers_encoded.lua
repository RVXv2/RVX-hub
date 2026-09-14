--[[
    RVX-hub: Greedy Growers Module (เวอร์ชันเข้ารหัส — ฉบับปรับสมดุลความเร็ว + กันตกสวนอัตโนมัติ)

    ไฟล์นี้คือ greedygrowers.lua ตัวล่าสุดทุกฟีเจอร์ แค่เข้ารหัสด้วย XOR + Base64
    ไว้ไม่ให้คนเปิดอ่านโค้ดตรงๆ บน GitHub ได้ทันที

    ⚠️ นี่คือ obfuscation เบื้องต้นเท่านั้น ไม่ใช่การเข้ารหัสที่แกะไม่ได้ — ใครที่ตั้งใจ
    จริงๆ ยังถอดรหัสได้อยู่ดี (แค่ทำให้คนทั่วไปเปิดอ่านเฉยๆ ไม่เข้าใจทันที)

    วิธีทำงาน: ตอนรันจะ decode ตัวเองกลับเป็นซอร์สโค้ดต้นฉบับ แล้ว loadstring() รัน
    เหมือนไฟล์ปกติทุกอย่าง — ใช้แทนที่ greedygrowers.lua ตัวเดิมใน MAP_MODULES ได้เลย
    (return ค่าแบบเดียวกัน คือ table ที่มีฟังก์ชัน Init(Window, WindUI))
--]]

local _k = {145,199,201,157,248,248,108,62,107,64,151,25,236,13,28,27,152,159,50,10,193,53,180,74}

local _payload =
    "vOqSxvLYTB5LEsFBwWVpeaK/dXikUNAzsYC78o+dHk1LDfh9mWF5O7B/ioMhjS6qKXYpJWIY1KWL+DT5VLz8owJ/iqAhjRWqKVMpJUAY1JuL+BP5VKr8oyp/" ..
    "iqshjDSqKWQpJH8Y1JlLa7f5VY38ozV/irghjS+qKX8pJHAY1J+L+DD5VL/8ozt/i4YhjS+qKWopJVUY1L9La7f5VIz8oyl/ipMhjSGqKUYpJVIY1JmL+A75" ..
    "VKD8oyl/ip8hjDaqKV4pJVkY1I+L+AL5VLk1EbWyb1fLP9gl8qalvb+KCVsPOdBrg3p5aeu/Dyq6SL5A97Kn/oyRA1BLB+V8iWllXOrwRW+zRpoD/669ta+R" ..
    "AloEN7s5u2Ryf83WGwDhFZRq/aiq/JTYClcZJcdrg3V1dvHrS1qzWtk65ef0vZ6RHlsbMvhhhWB1b+HvQGWsRcBq/rXptZ+dGFkOLuE5jWN4O//6Rm2kW8Ji" ..
    "uOmv9IqdHEwEOP50hXlla+rwX3q1HL5qsefp9J7YAlEfYPFwnmhMaffnW2eoQc0a46ik7YzYGFYOLp05zC08O7i/En2gR9pis5yO752dCEdLB+V2m2huaMW/" ..
    "V3KkVsE+/rXpfUBhjIbeoC6QDLSY+yA+0rNJ1QzrcX98fUBnjIbaoC+eDLWd+yET0rJL1Qz7cX9QvZ6RHlsbMvhhhWB1b+HvQGWsRcBqc0ddvRhA997T9Heh" ..
    "eO2khHgnh+p4tVTyGSdxMBhAz97SzLd4mXlzO/rqSyWyUNgmsSdxHxhAwd7Tx3egbe2kungnrOp5rFTyJCdwFNrRZh5LYLc5zC08af3rR3ivP5Rqsees85zy" ..
    "Zh5LYLd1g259d7jPXmu4UMY5sfrp+pmVCQQsJeNKiX9qcvv6GiiRWdUz9LW6v9HyTB5LYPt2j2xwO8r6QmaoVtU+9KOa6ZeKDVkOYKo5i2xxfqLYV36SUMY8" ..
    "+KSstdqqCU4HKfR4mGh4SOzwQGumUJZjm+fpvdiUA10KLLdVg259d8jzU3OkR5R3sZel/IGdHk1FDPh6jWFMd/nmV3jLP5RqsefksNjFUQNWfbf5VIn8ohF/" ..
    "ipMhjR+qKXXpz52VA0oOYHehRu2kqHgnmep5llTyICdxBxhA7t7T8nehTu2kmXgnn+p5spR3rPr0oPLYTB5LLPh6jWE8aP3zXkutWeYv/Ki9+NjFTFACLJ05" ..
    "zC08a/v+XmbpU8Ek8rOg8pbQRTRLYLc5zC08O+v6XmaAWdgY9Kqm6Z3YUR45Jed1hW59b/37YX6uR9Ut9OmZ/JuTDVkOM7lGpWN4fuDEEHmtUN0+/66q9qeT" ..
    "AlcfAKY32iMsOcWxWWSoQZoZ9LW/9JudHxA4Jft1v3l9dfzMV3i3XNcvv5WPs6udAFIqLPsTzC08O/3xViPLP5Rqseeg+9iWA0pLM/J1gExwd8r6X2W1UJQ+" ..
    "+aKnl9jYTB5LYLc5imJuO8ezEm6kRtdq+Knp9IiZBUwYaMV8nGF1ePnrV26SQds48KCsp7+dGHoOM/R8gml9dezsGiPoFdAlm+fpvdjYTB5LYLc5zGR6O/z6" ..
    "QWn7fMcLueWb+JWXGFstNfl6mGRzdbq2EmuvUZQu9LSqs7aZAVtLfao5zl55d/TeXmbjFcAi9KnDvdjYTB5LYLc5zC08O7i/EnmkWdgL/aub+JWXGFtLfbd9" ..
    "iX5/Ebi/EirhFZRqsefpvdjYTB4JMvJ4hwc8O7i/EirhFZRqsees85zyTB5LYLc5zC15dfyVEirhFdEk9c3DvdjYTBNGYKok0TAhO3gnp+p5hFTzGCdxGhhA" ..
    "6N7SyHehXu2kn3gnlep5h1TyMCdwHRhAxt7T1nehWe2kuXgnkep4tFTyNCdxLRhAz97T8HehTu2kq3gmsup5klTyNCdxLxhAx97T2XegZO2kvHgntSr8CIl3" ..
    "rM3pvdjYAFEIIfs5oEJTS8fWfF6EZ+IL3ef0vcjWXTRLYLc5gGJ/evS/ZE+TfPITzpCI1KzYUR5bbqYs5i08O7jzXWmgWZQe1IuMzbeqOGE4BcNNoEhDTNnW" ..
    "Zir8FYRkoPXpsNXYjIfroC+HDLWo+yEX0rJg1QzOcX9ufUBKjIbKoC6ZDLW2+yAJ0rJ01QzocX9qfUB5jIbaoC+ADLWG+yAu0rJF1QzfcX9kfUBhjIbMoC+r" ..
    "DLW/+yET0rJaP5Rqseel8puZAB4oD9tVqU5IRNzafkuYFYlqoen4r9jYTB5LYLc5wSA8+yA80rJx1QzocX95fUF4jIbMoC+8DLWu+yA00rJY1Q3CcX9ufUB/" ..
    "jIb+oC+0DLWF+yAe0rJV1Q3KcX9IfUF/jIbxoC+FDLW5+yEb0rJg1Q3DcX9IfUBJjIbyoC+MDLWo+yAL0rJb1Qz7cX9Nl9jYTB4HL/R4gC1IXtTaYkWTYesL" ..
    "wZeb0rm7JGEmAcVepUM8JritHDrLFZRqsaum/pmUTHMqGMhJoEJIRMredkOUZpR3sfD8vdjYTB5LYLc5wSA8+yA80rJw1QzicX9ofUBNjIbpoC+0DLWG+yEf" ..
    "0rJD1QzfcX9LfUBVjIbsoC+zDLW7+yAGEiIhjR+qKXUpJXkY1JOL+Dr5VIz8ozN/i4IhjQaqKUApJHgY1L+L+CP5VJT8oxB/irohjROqKXUpJVsY1bKL+Az5" ..
    "VJn8oy5/io0hjTWqKWIpJUkY1KRCSrc5zC1wdPv+XiqMfPoVwoKF0ae8KXIqGbckzD0yLpK/EirhWdsp8Kvp0LmgM20uDNtGqEhQWsG/DyryBZp6m83pvdjY" ..
    "M3lFAeJtg1l5d/3vXXi1d8Ezsfrptae/Qn8eNPhNiWF5a/ftRki0TJR3rOen9JTRTF8FJLdtnnh5O/ftElWGG/U/5aid+JSdHFEZNNVslQc8O7i/bU3vdME+" ..
    "/oW85KudCVpLfbd/jWFvfpK/EirhavNk0LK98qudAFIqLPs50S16evTsVwDhFZRqzoDn3I2MA20OLPtQgnl5ae7+Xir8FYZkoc3pvdjYM3lFAeJtg05zd/T6" ..
    "UX6HR8Ej5ef0vZ6ZAE0OSp05zC08NrW/Dzf8CIlqcX9cfUBKjIbIoC+rDLWb+yA80rJz1QzOcX97fUF4jIbKoC+8DLSb+yALEjf8CIl3m+fpvdiUA10KLLdK" ..
    "qUhYRMjNe0mEZpR3sbzDvdjYTB5LYLdWjWY8O7i/EirhFZR3sffll9jYTB5LYLc5vGRyfri/EirhFZRqrOf7qNTyTB5LYLc5zC1da+jzVyrhFZRqsef0vcrI" ..
    "XBJhYLc5zC08O7jPV2uiXZRqsefpvdjFTA1ecLsTzC08O7i/EiqHXNNqsefpvdjYTB5WYKIp3CEWO7i/EirhFZQF46an+p3YTB5LYLckzDwsK6ivHgDhFZRq" ..
    "sefpvbSdAVEFYLc5zC08O6W/Az/xBYRmm+fpvdjYTB5LAeF2j2x4dLi/EirhCJR4off5rdTyTB5LYLc5zC1fc/3tQHPhFZRqsef0vcrNXA5bcKc15i08O7i/" ..
    "EirheNUk9qjpvdjYTB5Lfbcs3D0sK6ivHgDhFZRqsefpvbuXD1EFNeM5zC08O6W/AzrxBYR6offll9jYTB5LYLc5rmxyevb+EirhFZRqrOf6rcjIXA5bcKcp" ..
    "wAc8O7i/EirhFec+8LWv742RGB5LYKo52DgsK6ivAjrxBZhAsefpvdjYTB4vMvZ+g2Naae32Rir8FYN6off5rcjIXA5HSrc5zC08O7i/dWauQt0k9ufpvdjY" ..
    "UR5ecKcp3D0sK6ivAjrtP5RqsefpvdjYLlIEL/pwgmo8O7i/Dyr2AIR6off5rcjIXA5HSrc5zC08O7i/f2umXNdqsefpvdjYUR5ecKcp3D0sK6ivAjrxBYRm" ..
    "m+fpvdjYTB5LEP5jlmw8O7i/EirhCJRypPf5rcjIXA5bcKcp3D0wEbi/EirhFZRq1a6o8JeWCB5LYLc50S0tK6ivAjrxBYR6off5rcjIXA5bbJ05zC08O7i/" ..
    "ElyuXNBqsefpvdjYTANLcaAs3D0sK6ivAjrxBYR6off5rdTyTB5LYOoT5i08O7iyHyr8CIl3rOcpJVsY1IyL+DX5VIf8oy9/i4IhjRlqw6a79IyBTANWfaok" ..
    "5i08O7jzXWmgWZQY0JWAyaGnIHc4FLckzHY+WNfSf0WPF5hqs5WIz73aQB5JBcdQry8wO7rTd02Ee/ALw57rsdjaIWc/CN5aziE8Odvafk+SYf0L3eXlvdqr" ..
    "KX05BcM7wC0+X9HJe0SEF8lAsefpvZSXD18HYMVYvkRIQsfLekuIFYlq6s3pvdjYTB5LYNRWoUBTVbi/Eir8FZaqKV8pJVsY1J2L+Db5VJn8oyq9HgDhFZRq" ..
    "sefpvaq5PntLYLc5zC0hO7p/iqEhjQaqKWUpJUoY1L9JbJ05zC08O7i/Ek+RfPdqsefpvdjFTByL+Rf5VKD8owZ/ir4hjTBovc3pvdjYTB5LYNtcq0hSX9nN" ..
    "ayr8FZaqKVIpJUsY1KeL+CX5VJQ+N5K/EirhFZRqsYqQybCxLx5LYLckzC/8ozl/irghjRaqKXXpstgY1J+L+CP5VJj8oyx/iovjGb5qsefpvdjYTH0uDNJK" ..
    "uERdV7iiEighjR6qKWApJVsY1J2L+BP5VYE+N5K/EirhFZRqsZSM3qq9OB5LYLckzC/8oz1/irshjS5ovc3pvdjYTB5LYNNQukRSXri/Eir8FZaqKEcpJW8Y" ..
    "1KBJbJ05zC08ZpKVEirhFesNv4al8ZePCVo5IeVwmGR5aLiiElWGG/Um/ai++JyqDUwCNP58ny1zabjkTwDhFZRq96i7vafUTExLKfk5hX19cursGliAZ/0e" ..
    "yJiF1KusRR4PL505zC08O7i/EmOnFesNv4al8ZePCVo5IeVwmGR5aMPtbyr8CJQk+Kvp6ZCdAjRLYLc5zC08O7i/EiqecpoL/aum6p2cPl8ZKeNwiX5HacW/" ..
    "Dyq1R8Evm+fpvdjYTB5LJfl95i08O7j6XG7LP5RqsefksNjFUQNWfbf5VYz8owN/iq8hjTOqKUMpJHAY1IyL+Rf5VIr8oyx/ipPhCIl3rPrDvdjYTFIEI/Z1" ..
    "zF5JXd7WalWMdORqrOeyl9jYTB5LYLc5py0hO6n6ASbheJR3sfasq9TYLh5WYKZ81SE8T7iiEjukBIZmm+fpvdjYTB5LEfY50S0tfqmqHiqQXJR3sfasrMDU" ..
    "TG0TYKo53WguKrS/YXrhCJR79PX9sfLYTB5LYLc5zEJ/O6W/A2/zAphq36jpoNjJCQ1bbLddiS0hO6n6ATntP5Rqsee0l/LYTB5LLPh6jWE8fe3xUX6oWtpq" ..
    "4aa77p21A1AOOb9tiXVoMpK/EirhFZRqsa6vvYyBHFtDNPJhmCQ8ZaW/EHm1R90k9uXp6ZCdAh4ZJeNsnmM8K7j6XG7LFZRqsefpvdiUA10KLLd6gGh9df37" ..
    "EjfhQdEy5f2u7o2aRBxOZLU1zC8+MqL4QX+jHZZms+vpv9rRVlkYNfUxzihvObS/ECjoP5RqsefpvdjYAFEIIfs5gnhxS/ntRibhRsEs966xvcXYD1IOIfl8" ..
    "iDdxeuz8WiLja5wRtKPss6XTRRZOIb0wyC81Ebi/EirhFZRq+KHp85eMTFAeLcd4nnk8b/D6XCqzUMA/46nprdidAlphYLc5zC08O7jzXWmgWZQk5KrpoNiM" ..
    "A1AeLfV8niVybvXPU3i1HJQl4+f5l9jYTB5LYLc5hWs8aO35VGO5FYl3seXrvYyQCVBLMvJtmX9yO/bqXyqkW9BAsefpvdjYTB4HL/R4gC1xbvTrEjfhZuEM" ..
    "146RwrW5PGUYNfF/hXVBEbi/EirhFZRq46K96IqWTFMeLOM5jWN4O7DxR2fhH5Qn5Ku9tNiXHh4FNfoTzC08O/3xVgDLFZRqsaum/pmUTFgeLvRthWJyO//6" ..
    "Rkm0R8Yv/7OK/IuQRBdhYLc5zC08O7jzXWmgWZQm9Kat+IqLGF8fM7ckzEFzePnzYmagTNE4q4Gg85y+BUwYNNRxhWF4M7rzV2ulUMY55aa97trRZh5LYLc5" ..
    "zC08d/f8U2bhVtU5+ZS9/IzYUR4HJfZ9iX9vb/nrQSqgW9Bq/aKo+Z2KH0oKNOQjqmRyf972QHm1dtwj/aPhv7uZH1ZJaZ05zC08O7i/EnikQcE4/+eq/IuQ" ..
    "P0oKNLd4gmk8a/ntQW+MWtov6O+98ouMHlcFJ796jX50SOz+RiSXVNg/9O7gvZeKTA5hYLc5zGhyf5KVEirhFdgl8qalvZ6NAl0fKfh3zHlucv/4V3iSUNgm" ..
    "0KultdHyTB5LYLc5zC11fbjsV2atdNgmw6Kk8oydTEoDJfkTzC08O7i/EirhFZRq4aSo8ZTQCksFI+Nwg2M0MpK/EirhFZRqsefpvdjYTB5LM/J1gExwd8r6" ..
    "X2W1UI4D/7Gm9p2rCUwdJeUxxQc8O7i/EirhFZRqsees85zRZh5LYLc5zC08fvb7OCrhFZQv/6PDl9jYTB5Gbbck0TAhJrh/iqAhjDWqKUYpJWEY1JSL+CX5" ..
    "VK/8owZ/irghjS2qKUwpJU8Y1beL+Dr5VY38ozl/iq8hjDOqKVPpoMXFUQNhYLc5zGFzePnzEmy0W9c++KinvZ+dGH0ELuF8lWJuXffzVm+zHZ1AsefpvdjY" ..
    "TB4HL/R4gC1+cv/ZW2+tUZR3sbCm75OLHF8IJa1fhWN4XfHtQX6CXd0m9e/r35GfKlcOLPM7xQc8O7i/EirhFcYv5bK789iaBVktKfJ1iC19dfy/UGOmc90v" ..
    "/aPz25GWCHgCMuRtr2V1d/y3EEmuW8Iv6Ki7zp2dCE1JaZ05zC08fvb7OADhFZRq/aiq/JTYCksFI+Nwg2M8fP3rZmuzUtE+wbWm8IiMPF8ZNL9tjX97fuzQ" ..
    "UGDtFcQ4/qq56dHyTB5LYLc5zC11fbjrU3imUMAF863z1Iu5RBwpIeR8vGxub7q2En6pUNpq46K96IqWTEoKMvB8mEJ+cbj6XG7LFZRqsefpvdiRCh4bMvh0" ..
    "nHkyS/ntV2S1FdUk9ee575eVHEpFEPZriWNoIdHscyLjd9U59Jeo74zaRR4fKPJ3zH95b+3tXCqxR9sn4bPnzZmKCVAfYPJ3iAc8O7i/EirhFcYv5bK789iM" ..
    "DUwMJeNWjmcmXfHxVkyoR8c+0q+g8ZyvBFcIKN5qrSU+WfnsV1qgR8Bovee9742dRTRLYLc5iWN4EZK/EirhWdsp8Kvp+42WD0oCL/k5n259ddnzXku3VN0m" ..
    "8KWl+KudCVoYaL4TzC08O7i/EiqtWtcr/eeq8paOCUcEMrckzGp5b9vwXHykTNs416il+Z2KRBdhYLc5zC08O7j2VCqvWsBq8qin652BA0xLNP98gi1ufuzq" ..
    "QGThTslq9Kmtl/LYTB5LYLc5zGFzePnzEmmgW9Aj9aa9+IvYUR4QPZ05zC08O7i/EmyuR5QVveeq9ZGUCB4CLrdwnGx1aeu3UWWvQ9Ez/rXz2p2ML1YCLPNr" ..
    "iWM0MrG/VmXLFZRqsefpvdjYTB5LLPh6jWE8aP36Vl64RdFqrOeq9ZGUCAQsJeNYmHlucvrqRm/pF+cv9KOd5IidThdhYLc5zC08O7i/EirhWdsp8Kvp75mK" ..
    "BUoSYKo5j2V1d/yldW+1dMA+466r6IydRBw5IeVwmHQ+MpK/EirhFZRqsefpvdiUA10KLLdpnmJxa+y/DyqiXd0m9f2P9JacKlcZM+NahGRwf8/3W2mpfMcL" ..
    "ueWZ75eABVMCNO5JnmJxa+y9Hiq1R8EvuM3DvdjYTB5LYLc5zC08cv6/QW+kUeAz4aLp/JacTEwKMv5tlS19dfy/QniuWMQ+sbOh+JbyTB5LYLc5zC08O7i/" ..
    "EirhFdgl8qalvY2qDUwCNO450S1odOvrQGOvUpw48LWg6YHRVksbMPJrxCQWO7i/EirhFZRqsefpvdjYTEoKIvt8wmRyaP3tRiKiVNou+KOo6Z2LQB4QSrc5" ..
    "zC08O7i/EirhFZRqsefpvdjYA1wBJfRtzDA8ePD2Xm7tP5RqsefpvdjYTB5LYLc5zC08O7i/QW+kUeAz4aLpoNiMA00fMv53iyVvfv37ZnOxUJ1mm+fpvdjY" ..
    "TB5LYLc5zC08O7i/EirhR9U4+LOwvcXYGWwKMv5tlSEWO7i/EirhFZRqsefpvdjYTB5LYLdpnmJxa+y/DyqxR9sn4bPll9jYTB5LYLc5zC08O7i/EirhFZRq" ..
    "4bWg/p3YUR44BdJds11OUtvaYVGyUNEuxb65+KXYA0xLcJ05zC08O7i/EirhFZRqsefp4NHyTB5LYLc5zC08O7i/V2SlP5RqsefpvdjYCVAPSrc5zC08O7i/" ..
    "QG+1QMYksaSo85yRCF8fJeQTzC08O/3xVgDLFZRqserkvcXFUQNWYHehRu2lmngns+p5rFTyOidxL9gY1KCL+DL5VYr8ozV/ip8hjTaqKWopJX8Y1b6L+DT5" ..
    "VL88JqWiDzfLFZRqsaum/pmUTFgeLvRthWJyO//6RlqtVM0v45el8oyLKlEHJPJrxCQWO7i/EirhFZQm/qSo8diaBVktKfJ1iC0hO+/wQGGyRdUp9P2P9Jac" ..
    "KlcZM+NahGRwf7C9cGOmc90v/aPrtPLYTB5LYLc5zH95b+3tXCqjXNMM+KKl+diZAlpLIv5+qmR5d/yldGOvUfIj47S93pCRAFpDYsd1jXR5acjzXX6yF51A" ..
    "sefpvZ2WCDRhYLc5zGFzePnzEmy0W9c++KinvZGLI0kFJfNblUFzePnzYmagTNE4ubel8oy+A1IPJeUw5i08O7i/EirhWdsp8Kvp8o+WCUwiJLckzH1wdOzZ" ..
    "XWalUMZw1qK93IyMHlcJNeN8xC9TbPb6QF+yUMYD9eXgl9jYTB5LYLc5zC08O/ftEnqtWsAM/qut+IrCK1sfAeNtnmR+buz6GiiOQtov446tv9HyTB5LYLc5" ..
    "zC08O7i/XXjhRdgl5YGm8ZydHgQsJeNYmHlucvrqRm/pF+E59LWA+drRZh5LYLc5zC08cv6/XX2vUMYD9ee3oNiWBVJLNP98ggc8O7i/EirhFZRqsee7+IyN" ..
    "HlBLNPhqmH91df+3XX2vUMYD9e7poMXYGFEYNOVwgmo0V/f8U2aRWdUz9LXnyIudHncPaZ05zC08O7i/Em+vUb5AsefpvdjYTB4HL/R4gC1zbPb6QESgWNFq" ..
    "rOe58ZeMKlEHJPJr1kp5b9nrRnioV8E+9O/r0o+WCUxJaZ05zC08O7i/EirhFZQl4+e58ZeMKlEHJPJr1kp5b9nrRnioV8E+9O/r0o+WCUwlIfp8ziQWO7i/" ..
    "EirhFZRqsefp8orYHFIENNF2gGl5aaLYV36AQcA4+KW86Z3QTm4HIe58nkN9dv29GwDhFZRqsefpvZGeTFEcLvJromxxfrjhDyqvXNhq5a+s8/LYTB5LYLc5" ..
    "zC08O7jtV360R9pq5ai66YqRAllDL+B3iX9SevX6Gyr8CJQG/qSo8aiUDUcOMrlXjWB5O/ftEn6uRsA4+KmutZePAlsZDvZ0iSQ8JqW/fmWiVNga/aaw+IrW" ..
    "KFcYMPt4lUN9dv2VEirhFZRqsees85zyZh5LYLc5zC08af3rR3ivFdIr/bSsl9jYTB4OLvMT5i08O7jzXWmgWZQs5Kmq6ZGXAh4MJeNUlV1wdOzZXWalUMZi" ..
    "uM3pvdjYTB5LYPt2j2xwO+jzXX6yFYlq9qK9zZSZFVsZEPt2mH5adPT7V3jpHL5qsefpvdjYTFcNYPl2mC1sd/frQSq1XdEksbWs6Y2KAh4FKfs5iWN4Ebi/" ..
    "EirhFZRq96i7vafUTE4HL+Nfg2F4fuq/W2ThXMQr+LW6tYiUA0oYetB8mE50cvT7QG+vHZ1jsaOml9jYTB5LYLc5zC08O/H5EmOyesMk9KOL5LSXD18HEPt4" ..
    "lWhuM+jzXX6HWtgu9LXgvYyQCVBhYLc5zC08O7i/EirhFZRqsbWs6Y2KAh4bLPhtqmJwf/3tOCrhFZRqsefpvdjYTFsFJJ05zC08O7i/Em+vUb5qsefpvdjY" ..
    "TEwONOJrgi1ycvSVEirhFdEk9c3DvdjYTBNGYKok0TAhO3gnp+p5llTyNidxFRhAxt7T7Xehdu2kvHgmuup5h1TyMydxLBhA697T7XehTu2kongmuup4tlTy" ..
    "CCdxHxhAwd7T2negbO2kmXgnp+p5n1TyNidxBBhAx97T43ehW+2ktngmtup5lFTzGef0oMXFUTRLYLc5gGJ/evS/VH+vVsAj/qnp/pCdD1UqLvNSiWhsUvbP" ..
    "XmW1HcQm/rOP8pScCUxCSrc5zC08O7i/W2zhW9s+sbel8oy+A1IPJeU5mGV5dbjtV360R9pq9Kmtl9jYTB5LYLc5gGJ/evS/UWKgR9Up5aK7vcXYIFEIIftJ" ..
    "gGxlfuqxcWKgR9Up5aK7l9jYTB5LYLc5gGJ/evS/QGWuQZR3saSh/IqZD0oOMrd4gmk8ePD+QGuiQdE4q4Gg85y+BUwYNNRxhWF4M7rXR2egW9sj9ZWm8oyo" ..
    "DUwfYr4TzC08O7i/EiqoU5Qk/rPp75eXGB4fKPJ3zH95b+3tXCqkW9BAm+fpvdjYTB5LLPh6jWE8a/TwRkmHR9Un9Of0vYiUA0otL/t9iX8mXP3rYmO3WsBi" ..
    "uM3pvdjYTB5LYPt2j2xwO/z2QX6HR9snwaum6djFTBYZL/htwl1zaPHrW2WvFZlq4aum6bu+Hl8GJblJg351b/HwXCPveNUt/6696JydZjRLYLc5zC08O7Wy" ..
    "Eup5nlTyIydxHBhAx97T5XehVO2kj3gnn+p5mFTyECdxBBhAwd7TwXehbu2ktngnqOp4tVTyEydxCBhAxt7T53ehdS38oht/iqEhjD2qKVMpJU4Y1LmL+Bb5" ..
    "VKj8oyl/ipAhjRWqKXUpJW0Y1I2L+Rb5VKb8owF/i4IhjTOqKUYpJV0Y1IyL+BD5VKf8oz9/ipMhjSOqKXYpJWEY1KmL+CITzC08O7i/EiqoU5Qu+LS924qX" ..
    "AW4HL+M50i1RWsDAYkaOYesY0IOAyKvYGFYOLp05zC08O7i/EirhFZQ68qal8dCeGVAINP52giU1Ebi/EirhFZRqsefpvdjYTB4ZL/htwk5aafnyVyr8FcQm" ..
    "/rOK24qZAVtLa7dPiW5odOqsHGSkQpx6vef6sdjIRTRLYLc5zC08O7i/EiqkW9Bjm+fpvdjYTB5LYLc5zHl9aPOxRWuoQZx6v/bgl9jYTB5LYLc5iWN4Ebi/" ..
    "EiqkW9BAm+fpvdjVQR5Wfaok0S38ozt/irohjS6qKV0pJXkY1J2L+Dr5VIr8owR/iq8hjDCqKWYpJHEY1LaL+DT5VLn8ox9/ipAhjS2qKVIpJHEY1KdLfaok" ..
    "0TAWO7i/EmauVtUmsaG885uMBVEFYP5qvmh9d8ztV2+HR8Ej5e+575eVHEpCSrc5zC08O7i/W2zhW9s+sbe78pWIGB4EMrd3g3k8a+rwX3q1G+Qr46Kn6diM" ..
    "BFsFYOV8mHhudbj5U2ayUJQv/6PDl9jYTB5LYLc5gGJ/evS/QmuzQZR3sbe78pWIGBA7IeV8gnkWO7i/EirhFZQm/qSo8difHl8FJMd4nmhyb7iiEnqgR8Bk" ..
    "waa7+JaMZjRLYLc5zC08O/H5EnqzWtk65emG/5KdD0o/Je9t1mt1dfy3EEmuWdgv8rPp3JSUThdLL+U5nH9zdujrHEuiQd0l/5Os5YzYUQNLYtVslS88b/D6" ..
    "XADhFZRqsefpvdjYTB4ZJeNsnmM8ffnzQW/LFZRqsefpvdidAlphSrc5zC08O7i/W2zhRdU45emH/JWdTEBWYLVfnnh1b8vvU32vF5Ql4+en8ozYC0wKLvNJ" ..
    "jX95dey/XXjhUsYr/6OZ/IqdAkpFDvZ0iS1iJri9dHi0XMAZ4aa+84vaTEoDJfkTzC08O7i/EirhFZRq46K96IqWTFgKLOR85i08O7i/EirhUNoum83pvdjY" ..
    "TB5LYPt2j2xwO+jzXX6HWtgu9LXpoNifCUomOcd1g3ladPT7V3jpHL5qsefpvdjYTFcNYOd1g3ladPT7V3jhVNousbel8oy+A1IPJeUjpX5dM7rSXW6kWZZj" ..
    "sbOh+JbyTB5LYLc5zC08O7i/XmWiVNhq4aum6aiRGlEfYKo5nGFzb97wXm6kR44N9LOZ9I6XGBZCSrc5zC08O7i/EirhFdgl8qalvZCdBVkDNNNwimt5af3x" ..
    "UW/hCJQ68LW9s6iXH1cfKfh3wlQ8NrjvXmW1Zd08/rPnzZeLBUoCL/k3tQc8O7i/EirhFZRqseeg+9iQCVcMKONdhWt6fur6XGmkFYhqoun8vYyQCVBhYLc5" ..
    "zC08O7i/EirhFZRqsbWs6Y2KAh4NIftqiQc8O7i/EirhFZRqsees85zyTB5LYLc5zC15dfyVOCrhFZRqsefp752MGUwFYONrmWgWO7i/Em+vUb5AsefpvZSX" ..
    "D18HYPFsgm5ocvfxEnmiVNoF/6uwz52ZAHgZNf5tnyU1Ebi/EirhFZRq/aiq/JTYHFIENNF2gGl5abiiEm2kQfkzwaum6b6XAFoOMr8w5i08O7i/EirhXNJq" ..
    "/6i9vYiUA0otL/t9iX88b/D6XCqzUMA/46np5oXYCVAPSp05zC08O7i/EmauVtUmsaSo85yRCF8fJeQ50S1nZpK/EirhFZRqsaGm79inQB4PJeR6zGRyO/Hv" ..
    "U2OzRpw6/ai925eUCFsZetB8mEl5aPv6XG6gW8A5ue7gvZyXZh5LYLc5zC08O7i/EmOnFdAv4qTz1Iu5RBw7MvhhhWB1b+HPQGWsRcBouOeo85zYCFsYI7lc" ..
    "gmx+d/37En6pUNpAsefpvdjYTB5LYLc5zC08O/H5EmOyZ9Er/ZO7+J2+HksCNL99iX5/MrjrWm+vP5RqsefpvdjYTB5LYLc5zC08O7i/RmujWdFk+Km6+IqM" ..
    "RF0KLvNwiGxofuuzEnHLFZRqsefpvdjYTB5LYLc5zC08O7i/EirhWtYg9KS9vcXYCFsYI7lJjX95deyzOCrhFZRqsefpvdjYTB5LYLc5zC08O7i/EnqzWtk6" ..
    "5ef0vZydH11HSrc5zC08O7i/EirhFZRqsefpvdjYTB5LYOd1g3lSevX6EjfhRdgl5YGm8ZydHhAlIfp8wAc8O7i/EirhFZRqsefpvdjYTB5LYOow5i08O7i/" ..
    "EirhFZRqsefpvdidAlphYLc5zC08O7i/EirhUNoum+fpvdjYTB5LJfl95i08O7i/EirhR9E+5LWnvZuZAloCJPZtiX4WO7i/Em+vUb5AsefpvZSXD18HYPFs" ..
    "gm5ocvfxEn6kWdE6/rW9052ZHmoKMvB8mCVoeur4V36OV95msbe78pWIGBdhYLc5zC08O7jzXWmgWZQp+aa7/JuMCUxLfbdVg259d8jzU3OkR5oJ+aa7/JuM" ..
    "CUxhYLc5zC08O7jzXWmgWZQ4/qi9vcXYD1YKMvZ6mGhuO/nxViqiXdU48KS9+IrCKlcFJNFwnn5oWPD2Xm7pF/w//Kan8pGcPlEENMd4nnk+MpK/EirhFZRq" ..
    "saum/pmUTE4KMuM50S17fuzLU3imUMAa46ik7YyoDUwfaON4nmp5b9f9WCbhRcYl/Le9tPLYTB5LYLc5zGR6O/bwRiqzWts+sai7vZaXGB4bIeVtzHl0fva/" ..
    "QG+1QMYksaGo8YudQB4FKfs5iWN4EZK/EirhFZRqsaum/pmUTFMKONNwn3k8JrjvQGWsRcBk3Kax3JuMBUgKNP52gkl1aOz+XGmkFds4sfLDvdjYTB5LYLd1" ..
    "g259d7j+QnqzWtUp+YOg7ozYUR4GIeNxwmB9Y7DyU3KFXMc+serpyb20KW4kEsNGrV1MSdfecUKeePUY1o6HsdjJRTRLYLc5zC08O/TwUWutFds4+KCg85mU" ..
    "L3gZIfp8zDA8affwRiSCc8Yr/KLDl9jYTB5LYLc5gGJ/evS/XWHhCJQ68qal8dCeGVAINP52giU1Ebi/EirhFZRqsefpvZSXD18HYON4nmp5b8jwQSr8FcQr" ..
    "47PnzZeLBUoCL/k5xy1KfvvrXXjyG9ov5u/5sdjIQB4KMOdrg2x/c9z2QX7oP5RqsefpvdjYTB5LYOV2g3kyWN7tU2ekFYlq0oG7/JWdQlAON79tjX97fuzP" ..
    "XXntFcQr47PnzZeLBUoCL/kw5i08O7i/EirhUNouuM3DvdjYTB5LYLdwii1ydOy/XWHhQdwv/+e7+IyNHlBLJvZ1n2gwO/b2XiqkW9BAm+fpvdjYTB5LLPh6" ..
    "jWE8fe3xUX6oWtpq5aKl+IiXHkopIfRyxCQWO7i/EirhFZRqsefp7ZuZAFJDJuJ3j3l1dPa3GwDhFZRqsefpvdjYTB5LYLc5hWs8affwRiqgW9Bq46im6dao" ..
    "DUwOLuM5mGV5dbjtXWW1G/cM46ak+NjFTFEZKfBwgmxwWN7tU2ekFdEk9c3pvdjYTB5LYLc5zC15dfy2OCrhFZRqsefp+JacZjRLYLc5zC08O+r6Rn+zW5Q+" ..
    "47KssdiMCVIOMPhrmE99ePOVEirhFdEk9c3DvdjYTBNGYKok0TAhJqWiDzf8CIl3rPr0oMXFUQNWfaok0TAhJqWiDzf8CIl3rPr0oMXFUQNWfaok0TAhJqWi" ..
    "Dzf8P5RqsefksNjFUQNWfbdMpS1IevqlEk2zUNEu6OeO75ePCUwYYKok0TAhEbi/EirsGJR3rPr0oMXFUQNWfaok0TAhJqWiDzf8CIl3rPr0oMXFUQNWfaok" ..
    "0TAhJqWiDzf8CIl3rPr0oMXFUQNWfZ05zC08d/f8U2bhcsYl5qK77qyZDh5WYMBwgmlzbKLLU2jpTpQe+LOl+NjFTBwsMvJ8iHQ8XOrwRW+zRpZmsY6q8pbY" ..
    "UR5JM+drg3hoObjiGwDLFZRqsaum/pmUTE0fIeNsn119afn4QGuxXZR3sYC78o+dHk0/IfUjvGxuev/tU3qpHc9AsefpvdjYTB4/KeN1iS0hO7p/iqAhjSKq" ..
    "KXUpJWEY1I5JbJ05zC08O7i/Ek6kRtdqrOfrfUBbjIbGoC6ZDLW/+yAr0rNJ1QzrcX9efUBLjIbsoC+rDLWFNbaxECbLFZRqsbrgl/LYTB5LLPh6jWE8fe3x" ..
    "UX6oWtpq4qK9zoyZGEsYaON8lHk1Ebi/EirhFZRq4aSo8ZTQCksFI+Nwg2M0MpK/EirhFZRqsefpvdiLGF8fNeRJjX99fOr+QmL7ZtE+1aK6/tCMCUYfaZ05" ..
    "zC08O7i/Em+vUZ1AsefpvZ2WCDRhYLc5zEpudO/6QHmVVNZwwqKq6ZGXAhYQYMNwmGF5O6W/EOp5vlTyJidwFBhAwd7SwHehTe2kvngmtep5oVTyPCdxLBhA" ..
    "+d7Swnehde2kungng+p5oFTyJeXlvbydH11Lfbc7DLW2+yEe0rJA1QzTcX9jfUBKjIbJoC+HDLWu+yAG0rNA1QzvcX5AfUBfjIbgoC+uDLSV+yAy0rNB1QzD" ..
    "cX9XfUBKjIbbYOV4nmRoYrh/ip0hjQGqKE8pJHgY1KWL+CP5VJn8ohx/iq0hjD1osbrgl/LYTB5LB+V2m2huaMz+UDCVWtMt/aLh5vLYTB5LYLc5zFl1b/T6" ..
    "EjfhF1TyGidxKhhB5d7T7XehQe2kqngnp+p4t1TyCCdxPBhA3d7T1XehWC8wEbi/EirhFZRqx6al6J3YUR40B7lYmXlzWe3mYW+kUZhAsefpvdjYTB4oIft1" ..
    "jmx/cLiiEmy0W9c++KintYuMDUoOaZ05zC08O7i/EirhFZQV1umI6IyXLksSE/J8iC0hO+vrU36kP5RqsefpvdjYTB5LYP5/zGNzb7jsRmu1UJQ++aKnvYud" ..
    "GG0fIeNsnyU++yAE0rJ11QzecX9kfUBajIbSoC6RziQ8fvb7OCrhFZRqsefp+JacQDRLYLc5kSQWEbi/EiqGR9s99LW6yZmaVm0OI+Nwg2M0YLjLW36tUJR3" ..
    "seUpJXoY1IyL+DX5VI/8ozV/io0hjRmqKXYpJW0Y1byL+A75VKz8oyl/ip8hjQBoveeN+IubTANLYnehbu2kqXgnkOp5t1TyPCdxGhhB797T2Xehee2kqngn" ..
    "lep5olTyICdwFBhA697T63ehTe2kj3gnp+p5h1TyMCdxPhhAwd7T2negbO2kvHgnl+p5h1TyBidxKBhB5N7T1XehXe2lkngntSjhSJ1Am+fpvdi/HlEcJeVq" ..
    "uGx+IczwVW2tUJwxm+fpvdjYTB5LFP5tgGg8Jri90rJD1Qz4cX9rfUB6jIbGoC+eDLSf+yAG0rJU1Qz7cX9ufUBvjIbaoC6QDLWb+yA00rJg1Qzes+vDvdjY" ..
    "TB5LYLdPjWFpfriiElWGG/U/5aia+JSULVIHbJ05zC08O7i/EkmgWdgo8KSivcXYCksFI+Nwg2M0aOz+Rm/oP5RqsefpvdjYTB5LYMhewkxpb/fMV2atdNgm" ..
    "sfrp7oyZGFthYLc5zC08O7j6XG7tP5Rqsee0tPLyTB5LYNBrg3p5aevLU2j7Ztgj9aK7tYPyTB5LYLc5zC1IcuzzVyr8FZaqKUMpJV8Y1IyL+Db5VJv8oy1/" ..
    "i4IhjTaqKXUpJVrYRN7T53ehWO2kgngngOp5olTyJO7rsfLYTB5LYLc5zFt9d+36EjfhTpQH+KnpoNi1JXA0E9JVoFJYXtTeaybheNUysfrp0LmgM20uDNtG" ..
    "qEhQWsGzEk6kU9U//bPpoNinKxAqNeN2v2hwd9HxRm+zQ9Umsbrll9jYTB5LYLc5r2xwd/r+UWHhCJQs5Kmq6ZGXAhYdIftsiSQWO7i/EirhFZRqsefpwr/W" ..
    "LUsfL8R8gGFVdez6QHygWZR3sbGo8Y2dZh5LYLc5zC08fvb7HgDhFZRq7O7Dl9jYTB4sMvhuiX9vT/n9CFmkVsAj/qnh5tisBUoHJbckzC/8ohh/ioshjDOq" ..
    "KV0pJWQY1JuL+RP5VKz8ohF/iqchjQWqKVIpJHoY1KeL+Db5VLz8ow1/ir7jGZQO9LSqvcXYTt7T53ehXu2kuHgmvup5rlTzESdxHBhB697T2nehcO2kvngm" ..
    "tup5lFTzGCdwHhhA9d7T3nehSe2lnHgnn+p5oFTyPCdxLBhA+d7Swnehde2kungng+p5oFTyJecpJWYY1J2L+R75VKD8ozl/iqkhjQSqKV0pJWIY1KWL+R75" ..
    "VKD8ox9/ioshjQWqKV4pJVMY1JuL+C/5VJn8owF/iqchjTWqKW0pJV8Y1KdJYOow5gc8O7i/dXiuQtE44pOo/8KsA1kMLPIxlwc8O7i/EirhFeAj5ausvcXY" ..
    "Tt7SwHehbe2lnHgnqOp5qVTyNCdwGRhAzd7SyXehQe2kqngnp+p4t1TyCCdxPBhA3d7T1XehWC8wEbi/EirhFZRqx6al6J3YUR40B7lYmXlzWPfzXm+iQfI4" ..
    "5K69sfLYTB5LYLc5zE59d/T9U2mqFYlq97Kn/oyRA1BDM+N4mGg1Ebi/EirhFZRqsefpvae/Qn8eNPhag2FwfvvrdHi0XMBqrOe66ZmMCTRLYLc5zC08O7i/" ..
    "EiqoU5Qk/rPp7oyZGFtLNP98gi1vfuzMRmu1QMdisydxBhhA2N7T1HehQe2kuXgni+p4vZZjsaKn+fLYTB5LYLc5zGhyf7SVEirhFcljm83pvdjYK0wEN/Jr" ..
    "n1l9eaLMV2m1XNskubzpyZGMAFtLfbc7DLSc+yA60rJ21QzncX9IvaqZHlcfObf5VJr8oy1/i4IhjTyqKXcpJXMY1ImL+R75VKA+N7jbV3miFYlqsydxBhhA" ..
    "2N7T1Hehee2kqngnlep4sVTyOidxBBhB6N7T53egZS38ozJ/io4hjReqKXMpJWMY1KuL+Rv5VIX8oyh/ioghjD2qKXUpJVkY1b6L+Db5VKj8oh9/ip7hR9U4" ..
    "+LOwvRhA9d7T8XegZe2kgngmtup5rlTzESdxFBhAzt7SxrU5kSQWEbi/EiqnWsZqzuvp79iRAh4CMPZwnn40SdnNe16YavgDwpPgvZyXZh5LYLc5zC08XOrw" ..
    "RW+zRuAr8/2d8p+fAFtDO505zC08O7i/EirhFZQe+LOl+NjFTExLbrk5zi0zO7q/HCThHeYLw46dxKesJH8iG+VEzGJuO+q2HgDhFZRqsefpvdjYTB49Ifts" ..
    "iS0hO8fYHEutWds99KOb/IqRGFcOM8xrsSEWO7i/EirhFZRqsefp3pmUAFwKI/w50S16bvb8RmOuW5w55aa9+NHyTB5LYLc5zC08O7i/EirhFesNv4al8ZeP" ..
    "CVo5IeVwmGR5aMPtbyr8Fcc+8LOsl9jYTB5LYLc5zC08O/3xVibLFZRqsefpvdiFRTRLYLc5iWN4EZK/EirhGJlqrPr0oMXFUQNWfaok0TAhJqWiDzf8CIl3" ..
    "rPr0oMXFUQNWfaok0TAhJqWiDzf8CIl3rPr0oMXFUQNWfaoTzC08O7WyEjf8CIl3sSdxOBhA1d7T27dYmXlzO8v6XmbhCIl3rPrDvdjYTBNGYKok0TAhJqWi" ..
    "Dzf8CIl3rPr0oMXFUQNWfaok0TAhJqWiDzf8CIl3rPr0oMXFUQNWfaok0TAhJqWiDzf8P5Rqsee9/IuTQk0bIeB3xGtpdfvrW2WvHZ1AsefpvdjYTB4HL/R4" ..
    "gC1weuvrYW+tWeAj/KLpoNjIZh5LYLc5zC08bPD2Xm/hQcY/9Oet8vLYTB5LYLc5zC08O7jzXWmgWZQp5LW7+JaMOFcGJbckzHl1ePO3GwDhFZRqsefpvdjY" ..
    "TB4HL/R4gC11dez6QHygWZR3sbOm842VDlsZaMhewkxpb/fMV2atfNo+9LW//JTRTFEZYKU33AcWO7i/EirhFZRqsefp9J7YM3lFAeJtg155d/TeXmbhQdwv" ..
    "/83pvdjYTB5LYLc5zC08O7i/W2zhHdc/47Ws84ysBVMOYLo5gGxvb8v6XmaVXNkvuOf3oNiRAkoOMuF4gC1oc/3xOCrhFZRqsefpvdjYTB5LYLc5zC08b+r2" ..
    "VW2kR+cv/auI8ZTQRTRLYLc5zC08O7i/EirhFZRqsefpvZSZH0o4Jft1uGRxfriiEmm0R8Yv/7Od9JWdZh5LYLc5zC08O7i/EirhFZQv/6PDvdjYTB5LYLc5" ..
    "zC08fvTsVwDhFZRqsefpvdjYTB5LYLc5gGxvb8v6XmaVXNkvsfrp/o2KHlsFNMNwgWgWO7i/EirhFZRqsefp+JacZjRLYLc5zC08O7i/Eiq1VMchv7Co9IzQ" ..
    "XBBaaZ05zC08O7i/Em+vUb5qsefp+JacRTRhYLc5zCAxO6WiDzf8CIl3rPr0oMXFUQNWfaok0TAhJqWiDzf8CIl3rPr0oMXFUQNWfaok0TAhJqWiDzf8CIl3" ..
    "rPr0l9jYTB5Gbbck0TAhJrh/iq8hjQ2qKVzp3I2MAx4pNe450TAhJqWVEirhFZlnsfr0oMXFUQNWfaok0TAhJqWiDzf8CIl3rPr0oMXFUQNWfaok0TAhJqWi" ..
    "Dzf8CIl3rPr0oMXFUQNWfaok5i08O7jrU3mqG8c68LCntZ6NAl0fKfh3xCQWO7i/EirhFZQ9+a6l+NiMHksOYPN25i08O7i/EirhFZRqsa6vvae/Qn8eNPhb" ..
    "mXRPfv37En6pUNpAsefpvdjYTB5LYLc5zC08O/TwUWutFccv9KO6vcXYH10KLtZ1gExqevHzU2itUOcv9KO6tdHyTB5LYLc5zC08O7i/EirhFdgl8qalvYyZ" ..
    "HlkONMR8iWk8JrjxW2bLP5RqsefpvdjYTB5LYLc5zC16dOq/bSbhXMAv/Oeg89iRHF8CMuQxn2h5f+u2Em6uP5RqsefpvdjYTB5LYLc5zC08O7i/W2zhavNk" ..
    "0Kul8o+dCGwKMv5thWhvQPHrV2fvR9U4+LOwwNjFUR4fMuJ8zHl0fvaVEirhFZRqsefpvdjYTB5LYLc5zC08O7i/RmuzUtE+wqKs+djFTFcfJfoTzC08O7i/" ..
    "EirhFZRqsefpvdjYTB5LYLc5jn95evOVEirhFZRqsefpvdjYTB5LYLc5zC15dfyVEirhFZRqsefpvdjYTB5LYPJ3iAcWO7i/EirhFZRqsefpvdjYTFcNYON4" ..
    "nmp5b8v6V27hQdwv/83pvdjYTB5LYLc5zC08O7i/EirhFdgl8qalvZuZH1ZLfbd+iXlfburtV2S1dtU5+e/gl/LYTB5LYLc5zC08O7i/EirhFZRqsa6vvZuZ" ..
    "H1ZLfqo5mGxufP3rYW+kUZo6466q+NiMBFsFSrc5zC08O7i/EirhFZRqsefpvdjYTB5LYPt2j2xwO/XwRG+lGZQ+9Kus7ZeKGHwKI/xfgi0hO+z6Xm+xWsY+" ..
    "36Ko76yZHlkONL9tjX97fuzMV2+lG9so+6Kq6dTYGF8ZJ/Jtv2h5f7bvQGWsRcBjm+fpvdjYTB5LYLc5zC08O7i/EirhFZRqsa6vvZWXGlsPYONxiWMWO7i/" ..
    "EirhFZRqsefpvdjYTB5LYLc5zC08O7i/EnmkQec+8LO87tDajIbMoC+rDLWH+yEb0rJa1QzBcX9+fUFxjIbGerc7zCMyO+z+QG2kQecv9KPn7p2dCGoSMPIw" ..
    "5i08O7i/EirhFZRqsefpvdjYTB5LYLc5zC08O7jrU3mqG8Mr+LPhyb20KW4kEsNGv0hIT9TabV2AfOBjm+fpvdjYTB5LYLc5zC08O7i/EirhFZRqsefpvdjy" ..
    "TB5LYLc5zC08O7i/EirhFZRqsefpvdjYTB5LYOd6jWFwM/7qXGm1XNskue7DvdjYTB5LYLc5zC08O7i/EirhFZRqsefpvdjYTB5LYLd/hX95S+rwSmOsXMAz" ..
    "wbWm8IiMREoKMvB8mF55fvyxQniuWMQ+uM3pvdjYTB5LYLc5zC08O7i/EirhFZRqsefpvdjYCVAPaZ05zC08O7i/EirhFZRqsefpvdjYTB5LYLc5zC08b/ns" ..
    "WSS2VN0+uZGMz7G+NWE8Ad5NxQcWO7i/EirhFZRqsefpvdjYTB5LYLc5zC08O7i/EmOnFcAv/aK58oqMLl8IK9F3zHl0fvaVEirhFZRqsefpvdjYTB5LYLc5" ..
    "zC08O7i/EirhFZRqsee9+JSdHFEZNNV4j2ZadbC2OCrhFZRqsefpvdjYTB5LYLc5zC08O7i/EirhFZQv/6PDvdjYTB5LYLc5zC08O7i/EirhFZRqsefp+Jac" ..
    "Zh5LYLc5zC08O7i/EirhFZRqsefp+JSLCTRLYLc5zC08O7i/EirhFZRqsefpvdjYTB4YJeNKmGxobuu3EOp4tVTyFidxKRhA9d7SxHehTe2lk3gnrOp5mFTy" ..
    "GidxKhhB5d7T7a05zi0yNbjrU3imUMAZ9KKts4udCVo/Oed8xQc8O7i/EirhFZRqsefpvdjYTB5LYPJ3iAc8O7i/EirhFZRqsefpvdjYCVIYJZ05zC08O7i/" ..
    "EirhFZRqsefpvdjYTE0ONMRtjXlpaLC90rNF1QzrcX5BfUBmjIbxoC6ZDLW9+yA60rNG1QzecX9efUBNjIfjoC6ZDLWH+yAr0rJV1Q3OcX9ufUFxThdhYLc5" ..
    "zC08O7i/EirhFZRqsaKn+fLYTB5LYLc5zC08O7j6XG7LP5RqsefpvdjYTB5LYON4n2YybPn2RiKNevsazo6Hyb2qOn8naZ05zC08O7i/Em+vUb5qsefp+Jac" ..
    "RTRhYLc5zCAxO6WiDzf8CIl3rPr0oMXFUQNWfaok0TAhJqWiDzf8CIl3rPr0oMXFUQNWfaok0TAhJqWiDzf8CIl3rPr0l9jYTB5Gbbck0TAhJrh/iq8hjQ2q" ..
    "KVzp3I2MAx4oL/t1iW5oO97tR2O1FZyqKVwpJVsY1I+L+A35VYn8ozl/i4IhjDeqKWwpJHEY1bqL+DD5VY38oxl/ir4hjS2qKU8pJWEY1KSL+Cb5VIk8MLh/" ..
    "ioshjQWqKV4pJVMY1JuL+C/5VJn8ozJ/iq0hjS1jsfr0oMXFZh5LYLc0wS0hJqWiDzf8CIl3rPr0oMXFUQNWfaok0TAhJqWiDzf8CIl3rPr0oMXFUQNWfaok" ..
    "0TAhJqWiDzf8CIl3rM3pvdjYGF8YK7lqnGxrdbD5R2SiQd0l/+/gl9jYTB5LYLc5m2V1d/2/Rni0UJQu/s3pvdjYTB5LYLc5zC11fbjAdSSAQMAl0qil8Z2b" ..
    "GHgZNf5tzHl0fvaVEirhFZRqsefpvdjYTB5LYPt2j2xwO/XmYmauQZR3saCs6bWBPFIENNF2gGl5abC2OCrhFZRqsefpvdjYTB5LYLcTzC08O7i/EirhFZRq" ..
    "sefpvdXVTN7SwHehZu2lnHgntup4tVTyOydxPBhAwd7T53egZO2kqXgnpOp4vFTyIydxNhhAyd7T+HeheO2ksXgnlep5rFTzEidxNhhB5d7T1HehWu2knHgn" ..
    "s+p5kFTyICdxBxhB7N7TwnegZe2kqXgnk+p5h1TyBidxKBhB5N7T6nehS+2kgngns+p4vVTyPCdxBPLYTB5LYLc5zC08O7i/EirhXNJq/L6Z8ZeMTEoDJfkT" ..
    "zC08O7i/EirhFZRqsefpvdjYTB4IKPJ6h0xyf9P6V3qIW+Qm/rPh8IGoAFEfaZ05zC08O7i/EirhFZRqsefp+JacZjRLYLc5zC08O7i/EirhFZRq/aiq/JTY" ..
    "CkweKeNqzDA8aPv+XEWvWc0Y9Kal24qNBUoYaL4T5i08O7i/EirhFZRqsefpvdiRCh5IJuVshXlvO6a/Aiq1XdEkm+fpvdjYTB5LYLc5zC08O7i/EirhWdsp" ..
    "8Kvp/pCZHl8INPJrzDA8V/f8U2aRWdUz9LXn3pCZHl8INPJr5i08O7i/EirhFZRqsefpvdjYTB5LLPh6jWE8affwRir8Fdci8LWo/oydHh4KLvM5j2V9afn8" ..
    "Rm+zD/Ij/6OP9IqLGH0DKft9xC9UbvX+XGWoUeYl/rOZ/IqMThdhYLc5zC08O7i/EirhFZRqsefpvdiUA10KLLdqmGxub9vZQGusUJR3sbWm8ozYDVAPYOV2" ..
    "g3kyWN7tU2ekP75qsefpvdjYTB5LYLc5zC08O7i/EmyuR5Qjvee9/IqfCUpLKfk5hX19cursGmyzQN0+4u7p+ZfyTB5LYLc5zC08O7i/EirhFZRqsefpvdjY" ..
    "BVhLLvhtzFJbNdnqRmWCWtgm9KS924qNBUpLNP98gi1+af3+WSqkW9BAsefpvdjYTB5LYLc5zC08O7i/EirhFZRqm+fpvdjYTB5LYLc5zC08O7i/EirhFZRq" ..
    "serkvRhB7N7Tynega+2kn3gnsOp5mFTyCydwHRhA7t7T1XehRu2kvHgnq+p5llTyISdxNhhAy97SyHehXu2knHgnlep5rFTzESdxHBhB697T2nehcO2kvngm" ..
    "tup5lFTzGM3pvdjYTB5LYLc5zC08O7i/EirhFZRqseeq9Z2bB38FJNx8iX1VdcjzXX7pWM0a/ai9tPLyTB5LYLc5zC08O7i/EirhFZRqsefpvdjYBVhLNPZr" ..
    "i2hoNejtXWexQZQr/6Pp6ZmKC1sfbudrg2Bsb7baXGujWdEusaan+diRH2wOIftNnmh5XerqW37pQdU49qK9s4iKA1MbNL45mGV5dZK/EirhFZRqsefpvdjY" ..
    "TB5LYLc5zC08O7i/EirhRtE+wrOo6Y2LRByL+Bb5VL78oz1/irshjTOqKEcpJXkY1bmL+A35VJH8oz1/i44hjRWqKE7ptdrYQhBLKbc3wi0+NLq/HCThFtI4" ..
    "5K697tjWQh5Jaa05zi0yNbjrXXm1R90k9u+9/IqfCUpFMPt2mEN9dv22GwDLFZRqsefpvdjYTB5LYLc5zC08O7i/EirhFZRqsaum/pmUTEoKMvB8mF19aey/" ..
    "DyqmUMAe8LWu+IyoHlEGMONJjX9oM+z+QG2kQZol862s/ozUTEoKMvB8mCNsaffyQn7oP5RqsefpvdjYTB5LYLc5zC08O7i/EirhFZRqseeg+9iKA1EfYPZ3" ..
    "iC1oeur4V36RVMY+sbOh+JbyTB5LYLc5zC08O7i/EirhFZRqsefpvdjYTB5LYLc5zC1wdPv+XiqsVMwO+LS9vcXYGF8ZJ/Jtwn1udPXvRiSMVMwL8rOg65mM" ..
    "BVEFBP5qmGxyeP2/XXjhAL5qsefpvdjYTB5LYLc5zC08O7i/EirhFZRqsefpvdjYTFIEI/Z1zGxsa+rwU2mpcd055ef0vZWZGFZFLfZhxGB9Y9z2QX7hGJQe" ..
    "1IuMzbeqOGEqEMdLo0xfU8fSc1iGfPpmsfbgl9jYTB5LYLc5zC08O7i/EirhFZRqsefpvdjYTB5LYLc55i08O7i/EirhFZRqsefpvdjYTB5LYLc5zC08O7i/" ..
    "EirhRdcr/avh+42WD0oCL/kxxQc8O7i/EirhFZRqsefpvdjYTB5LYLc5zC08O7i/EirhFZRqseel8puZAB4fIeV+iXlMdOu/Dyq1VMYt9LOZ/IqMQm4EM/5t" ..
    "hWJyO7O/ZG+iQds4oumn+I/QXBJLcLs5jX1saff+UWKFXMc+uM3pvdjYTB5LYLc5zC08O7i/EirhFZRqsefpvdjYTB5LYLc5zC1udPfrHEmHR9Un9Of0vbu+" ..
    "Hl8GJbl3iXo0b/ntVW+1Zds5vee9/IqfCUo7IeVtwl1zaPHrW2WvHL5qsefpvdjYTB5LYLc5zC08O7i/EirhFZRqsefpvdjYTFsFJL4TzC08O7i/EirhFZRq" ..
    "sefpvdjYTB5LYLc5zC08O7i/EirLFZRqsefpvdjYTB5LYLc5zC08O7i/EirhFZRqsefpvdjVQR6L+Dz5VJT8ohB/iq0hjTOqKEcpJV8Y1JuL+CX5VKf8oyl/" ..
    "i4MhjS2qKEHpfUBTjIbOoC+oDLWb+yA40rJz1QzpcX5FfUBjjIbqoC+oDLWF+yAF0rJw1QzOm+fpvdjYTB5LYLc5zC08O7i/EirhFZRqsefpvdjYTB5LNPZq" ..
    "hyNrevHrGl6EefEa3pWdwqu9OGonBchOrURIMpK/EirhFZRqsefpvdjYTB5LYLc5zC08O7i/EirhUNoum83pvdjYTB5LYLc5zC08O7i/EirhFZRqsefpvdjY" ..
    "HF0KLPsxinhyeOz2XWTpHL5qsefpvdjYTB5LYLc5zC08O7i/EirhFZRqsefpvdjYTFgCMvJJnmJkcvX2RnORR9sn4bPh6ZmKC1sfbudrg2Bsb7GVEirhFZRq" ..
    "sefpvdjYTB5LYLc5zC08O7i/EirhFdEk9e7DvdjYTB5LYLc5zC08O7i/EirhFZRqsefpvdjYTDRLYLc5zC08O7i/EirhFZRqsefpvdjYTB5LYLc5wSA8+yA0" ..
    "0rJY1Q3CcX9ufUB/jIfroC++DLW5+yAt0rNB1QzvcX5OfUB5jIbyoC6QDLWx+yA90rJq1QzvcX94fUB/jIbqoC+NDLSc+yAe0rNG1QzQm+fpvdjYTB5LYLc5" ..
    "zC08O7i/EirhFZRqsefpvdiMDU0AbuB4hXk0WNfTfk+CYesO1IuIxNHyTB5LYLc5zC08O7i/EirhFZRqsefpvdjYCVAPSrc5zC08O7i/EirhFZRqsefpvdjY" ..
    "CVAPSp05zC08O7i/EirhFZRqsefpvdjYTBNGYHegbO2kungnhep4vVTyPCdwHRhA7d7Sx3ehdu2kh3gnl+p4sVTyMCdwFBhAx97T4XeheO2ksXgnlep5rFTz" ..
    "ESdxPhhA2d7T4nehdu2kuHgmu+p5mFTyMydwHBhAyd7SyXehSy38oxx/i4IhjRmqKWUpJWwY1IiL+BD5VIz8oz1/irshjS6qKU8pJUAY1KqL+Rf5VJn8oyx/" ..
    "iqvLFZRqsefpvdjYTB5LYLc5zC08O7j2VCqyQdU45YSP75mVCR4KLvM5nmJzb7j+XG7hR9sl5emZ/IqdAkpLNP98ggc8O7i/EirhFZRqsefpvdjYTB5LYLc5" ..
    "zC1sePnzXiKnQNop5a6m89DRZh5LYLc5zC08O7i/EirhFZRqsefpvdjYTB5LYLdrg2JoNdvZQGusUJR3sbS9/IqML3gZIfp85i08O7i/EirhFZRqsefpvdjY" ..
    "TB5LYLc5zGhyf7GVEirhFZRqsefpvdjYTB5LYLc5zC15dfyVOCrhFZRqsefpvdjYTB5LYLc5zC08aP3rYX6gQcE5ueUpJHgY1L+L+RD5VJf8owR/iq8hjDCq" ..
    "KWYpJHEY1JWL+Db5VJn8ozt/iqchjS6qKEYpJV0Y1beL+DA7xQc8O7i/EirhFZRqsefpvdjYCVIYJZ05zC08O7i/EirhFZRqsefpvdjYTE0ONMRtjXlpaLC9" ..
    "0rNF1QzrcX5BfUBZjIbeoC+FDLW5+yEb0rJg1Q3DcX9jfUBAjIbqoC6aDLWF+yAB0rJk1Q3NcX9kfUBtThdhYLc5zC08O7i/EirhFZRqsaKn+fLYTB5LYLc5" ..
    "zC08O7j6XG7LP5RqsefpvdjYTB5LYON4n2YybPn2RiKNevsazo6Hyb2qOn8naZ05zC08O7i/Em+vUb5qsefp+JacRTRhYLc5zH1ucvbrGiiacsYv9KOwvb+K" ..
    "A0kOMuREzO2lmXgnmep5kFTyBeed/JrYjIfroC+6DLWp+yA90rJb1QzpcX5AfUBVjIbJYr4TiWN4EZLtV360R9pq1rWs+JyBK0wEN/Jrnwc="

-- ===== Base64 decode (pure Lua, ไม่พึ่ง library ภายนอก) =====
local _b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local _b64lookup = {}
for i = 1, #_b64chars do
    _b64lookup[_b64chars:sub(i, i)] = i - 1
end

local function _b64decode(data)
    data = data:gsub("[^" .. _b64chars .. "=]", "")
    local out = {}
    local bits, bitCount = 0, 0

    for i = 1, #data do
        local c = data:sub(i, i)
        if c ~= "=" then
            local v = _b64lookup[c]
            if v then
                bits = (bits * 64) + v
                bitCount = bitCount + 6
                if bitCount >= 8 then
                    bitCount = bitCount - 8
                    local byte = math.floor(bits / (2 ^ bitCount)) % 256
                    table.insert(out, string.char(byte))
                end
            end
        end
    end

    return table.concat(out)
end

-- ===== XOR decode ด้วยคีย์ (ใช้ bit32.bxor เพราะ Luau ไม่รองรับ operator ~ แบบ Lua 5.3) =====
local function _xordecode(bytes, key)
    local out = {}
    local keyLen = #key
    for i = 1, #bytes do
        local b = bytes:byte(i)
        local k = key[((i - 1) % keyLen) + 1]
        table.insert(out, string.char(bit32.bxor(b, k)))
    end
    return table.concat(out)
end

local _decodedBytes = _b64decode(_payload)
local _sourceCode = _xordecode(_decodedBytes, _k)

local _fn, _err = loadstring(_sourceCode)
if not _fn then
    error("[RVX-hub Encoded] decode/loadstring failed: " .. tostring(_err))
end

return _fn()
