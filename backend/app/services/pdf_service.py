import io
import logging
from typing import Dict, Any

logger = logging.getLogger("nylex.pdf")

def generate_invoice_pdf(invoice: Dict[str, Any], client: Dict[str, Any]) -> bytes:
    """
    Generates a professional PDF document for an Invoice using ReportLab.
    """
    try:
        from reportlab.lib.pagesizes import letter
        from reportlab.lib import colors
        from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=letter, rightMargin=36, leftMargin=36, topMargin=36, bottomMargin=36)
        elements = []
        styles = getSampleStyleSheet()

        # Header Title
        title_style = ParagraphStyle(
            name="TitleStyle",
            parent=styles["Heading1"],
            fontSize=24,
            leading=28,
            textColor=colors.HexColor("#0D47A1"),
            spaceAfter=6,
        )
        elements.append(Paragraph("NYLEX DIGITAL", title_style))
        elements.append(Paragraph("Premium Web & Digital Solutions | www.nylex.online", styles["Normal"]))
        elements.append(Spacer(1, 16))

        # Invoice Banner
        inv_title = f"INVOICE: {invoice.get('invoiceNumber', '')}"
        elements.append(Paragraph(f"<b>{inv_title}</b>", styles["Heading2"]))
        elements.append(Spacer(1, 8))

        # Metadata Table
        meta_data = [
            ["Billed To:", f"{client.get('businessName', '')} ({client.get('clientName', '')})", "Invoice Date:", invoice.get("invoiceDate", "")],
            ["Phone / Email:", f"{client.get('phone', '')} | {client.get('email', '') or 'N/A'}", "Due Date:", invoice.get("dueDate", "")],
            ["Address:", client.get("address", "N/A"), "Status:", invoice.get("status", "").upper()]
        ]
        t_meta = Table(meta_data, colWidths=[100, 200, 90, 150])
        t_meta.setStyle(TableStyle([
            ('FONTNAME', (0,0), (-1,-1), 'Helvetica'),
            ('FONTSIZE', (0,0), (-1,-1), 9),
            ('TEXTCOLOR', (0,0), (-1,-1), colors.HexColor("#333333")),
            ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ]))
        elements.append(t_meta)
        elements.append(Spacer(1, 16))

        # Line Items Table
        items_data = [["Item Description", "Qty", "Rate (₹)", "Amount (₹)"]]
        for item in invoice.get("items", []):
            items_data.append([
                item.get("description", ""),
                str(item.get("quantity", 1)),
                f"₹{float(item.get('rate', 0)):,.2f}",
                f"₹{float(item.get('amount', 0)):,.2f}"
            ])
        
        t_items = Table(items_data, colWidths=[280, 50, 100, 110])
        t_items.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#0D47A1")),
            ('TEXTCOLOR', (0,0), (-1,0), colors.white),
            ('ALIGN', (0,0), (-1,-1), 'LEFT'),
            ('ALIGN', (1,0), (-1,-1), 'RIGHT'),
            ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
            ('FONTSIZE', (0,0), (-1,0), 9),
            ('BOTTOMPADDING', (0,0), (-1,-1), 6),
            ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E0E0E0")),
        ]))
        elements.append(t_items)
        elements.append(Spacer(1, 12))

        # Summary Totals Table
        totals_data = [
            ["Subtotal:", f"₹{float(invoice.get('subtotal', 0)):,.2f}"],
            ["Discount:", f"- ₹{float(invoice.get('discount', 0)):,.2f}"],
            [f"Tax ({invoice.get('taxRate', 0)}%):", f"₹{float(invoice.get('tax', 0)):,.2f}"],
            ["Grand Total:", f"₹{float(invoice.get('total', 0)):,.2f}"],
            ["Paid Amount:", f"₹{float(invoice.get('paidAmount', 0)):,.2f}"],
            ["Balance Due:", f"₹{float(invoice.get('balanceAmount', 0)):,.2f}"]
        ]
        t_totals = Table(totals_data, colWidths=[430, 110])
        t_totals.setStyle(TableStyle([
            ('ALIGN', (0,0), (-1,-1), 'RIGHT'),
            ('FONTNAME', (0,-3), (-1,-1), 'Helvetica-Bold'),
            ('TEXTCOLOR', (0,-1), (-1,-1), colors.HexColor("#C62828")),
            ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ]))
        elements.append(t_totals)

        if invoice.get("notes"):
            elements.append(Spacer(1, 16))
            elements.append(Paragraph(f"<b>Notes & Payment Details:</b><br/>{invoice.get('notes')}", styles["Normal"]))

        doc.build(elements)
        buffer.seek(0)
        return buffer.getvalue()
    except Exception as e:
        logger.error(f"Error generating Invoice PDF: {e}")
        # Return fallback text-based PDF bytes
        return f"%PDF-1.4 Invoice: {invoice.get('invoiceNumber')} Total: {invoice.get('total')}".encode('utf-8')

def generate_quotation_pdf(quotation: Dict[str, Any], client: Dict[str, Any]) -> bytes:
    """
    Generates a professional PDF document for a Quotation using ReportLab.
    """
    try:
        from reportlab.lib.pagesizes import letter
        from reportlab.lib import colors
        from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=letter, rightMargin=36, leftMargin=36, topMargin=36, bottomMargin=36)
        elements = []
        styles = getSampleStyleSheet()

        title_style = ParagraphStyle(
            name="QuoTitle",
            parent=styles["Heading1"],
            fontSize=24,
            leading=28,
            textColor=colors.HexColor("#1B5E20"),
            spaceAfter=6,
        )
        elements.append(Paragraph("NYLEX DIGITAL", title_style))
        elements.append(Paragraph("Formal Proposal & Quotation | www.nylex.online", styles["Normal"]))
        elements.append(Spacer(1, 16))

        elements.append(Paragraph(f"<b>QUOTATION: {quotation.get('quotationNumber', '')}</b>", styles["Heading2"]))
        elements.append(Spacer(1, 8))

        meta_data = [
            ["Prepared For:", f"{client.get('businessName', '')} ({client.get('clientName', '')})", "Quotation Date:", quotation.get("quotationDate", "")],
            ["Phone / Email:", f"{client.get('phone', '')} | {client.get('email', '') or 'N/A'}", "Valid Until:", quotation.get("validUntil", "") or "30 Days"],
            ["Status:", quotation.get("status", "").upper(), "", ""]
        ]
        t_meta = Table(meta_data, colWidths=[100, 200, 90, 150])
        t_meta.setStyle(TableStyle([
            ('FONTNAME', (0,0), (-1,-1), 'Helvetica'),
            ('FONTSIZE', (0,0), (-1,-1), 9),
            ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ]))
        elements.append(t_meta)
        elements.append(Spacer(1, 16))

        items_data = [["Scope / Description", "Qty", "Unit Price (₹)", "Amount (₹)"]]
        for item in quotation.get("items", []):
            items_data.append([
                item.get("description", ""),
                str(item.get("quantity", 1)),
                f"₹{float(item.get('rate', 0)):,.2f}",
                f"₹{float(item.get('amount', 0)):,.2f}"
            ])
        
        t_items = Table(items_data, colWidths=[280, 50, 100, 110])
        t_items.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#1B5E20")),
            ('TEXTCOLOR', (0,0), (-1,0), colors.white),
            ('ALIGN', (0,0), (-1,-1), 'LEFT'),
            ('ALIGN', (1,0), (-1,-1), 'RIGHT'),
            ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
            ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E0E0E0")),
            ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ]))
        elements.append(t_items)
        elements.append(Spacer(1, 12))

        totals_data = [
            ["Subtotal:", f"₹{float(quotation.get('subtotal', 0)):,.2f}"],
            ["Discount:", f"- ₹{float(quotation.get('discount', 0)):,.2f}"],
            [f"Tax ({quotation.get('taxRate', 0)}%):", f"₹{float(quotation.get('tax', 0)):,.2f}"],
            ["Estimated Total:", f"₹{float(quotation.get('total', 0)):,.2f}"],
        ]
        t_totals = Table(totals_data, colWidths=[430, 110])
        t_totals.setStyle(TableStyle([
            ('ALIGN', (0,0), (-1,-1), 'RIGHT'),
            ('FONTNAME', (0,-1), (-1,-1), 'Helvetica-Bold'),
            ('TEXTCOLOR', (0,-1), (-1,-1), colors.HexColor("#1B5E20")),
            ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ]))
        elements.append(t_totals)

        if quotation.get("notes"):
            elements.append(Spacer(1, 16))
            elements.append(Paragraph(f"<b>Terms & Conditions:</b><br/>{quotation.get('notes')}", styles["Normal"]))

        doc.build(elements)
        buffer.seek(0)
        return buffer.getvalue()
    except Exception as e:
        logger.error(f"Error generating Quotation PDF: {e}")
        return f"%PDF-1.4 Quotation: {quotation.get('quotationNumber')} Total: {quotation.get('total')}".encode('utf-8')
